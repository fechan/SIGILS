--- pipe.lua: Functions for making pipes in the factory actually
--- transfer items

---A data structure for a Pipe matching `/server/src/types/core-types.ts#Pipe`
---@class Pipe

local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')
local PipeModeFluid = require('sigils.pipeModes.fluid')
local Filter = require('sigils.filter')
local PipeGraph = require('sigils.PipeGraph')
local PipeSaturation = require('sigils.PipeSaturation')
local FibonacciHeap = require('sigils.FibonacciHeap')
local LOGGER = require('sigils.logging').LOGGER

local ITEM_PIPE_MODES = {
  natural = require('sigils.pipeModes.natural'),
  spread = require('sigils.pipeModes.spread'),
}

local function processFluidPipe (pipe, groupMap, missingPeriphs)
  local filter = Filter.getFilterFn(pipe.filter)

  local ok, transferOrders = pcall(
    function ()
      return PipeModeFluid.getTransferOrders(groupMap[pipe.from], groupMap[pipe.to], missingPeriphs, filter)
    end
  )

  if ok then
    local coros = {}
    for _, order in ipairs(transferOrders) do
      local fromPeriph = peripheral.wrap(order.from.periphId)
      local coro = function ()
        pcall(function ()
          fromPeriph.pushFluid(order.to.periphId)
        end)
      end
      table.insert(coros, coro)
    end
    parallel.waitForAll(unpack(coros))
  else
    LOGGER:warn("pipe.lua#processFluidPipe() caught error " .. transferOrders)
  end
end

---Transfer items or fluids across a single pipe
---@param pipe Pipe Pipe to transfer items or fluids across
---@param groupMap table<string, Group> A table mapping Group IDs to Groups
---@param missingPeriphs table<string, boolean> A set of peripherals that are missing
local function processPipe (pipe, groupMap, missingPeriphs)
  local filter = Filter.getFilterFn(pipe.filter)

  local ok, transferOrders = pcall(
    function ()
      local pipeMode = ITEM_PIPE_MODES[pipe.mode] or ITEM_PIPE_MODES["natural"]
      return pipeMode.getTransferOrders(groupMap[pipe.from], groupMap[pipe.to], missingPeriphs, filter)
    end
  )

  if ok then
    local coros = {}
    for i, order in ipairs(transferOrders) do
      local fromPeriph = peripheral.wrap(order.from.periphId)
      local coro = function ()
        pcall(function ()
          fromPeriph.pushItems(order.to.periphId, order.from.slot, order.limit, order.to.slot)
        end)
      end
      table.insert(coros, coro)
    end
    if #coros > 0 then
      parallel.waitForAll(unpack(coros))
    end
  else
    LOGGER:warn("pipe.lua#processPipe() caught error " .. transferOrders)
  end
end

--[[
  Treats pipes as vertices in a graph, and colors them with DSatur
  https://en.wikipedia.org/wiki/DSatur
  Each color represents a batch of pipes to run in parallel
]]
local function batchPipes (factory)
  local connectedPipes = PipeGraph.new(factory)

  local heap = FibonacciHeap.new() -- build a heap of pipe IDs needing processing
  local heapNodes = {} -- map Pipe IDs to their node in the heap
  for pipeId, _ in pairs(factory.pipes) do
    local degree = connectedPipes:getDegree(pipeId)
    local pipeSatData = PipeSaturation.new(degree, pipeId)
    local node = heap:insert(pipeSatData, pipeSatData)
    heapNodes[pipeId] = node
  end

  -- start running DSatur
  local pipeColors = {} -- Maps color IDs to sets of pipe IDs of the same color
  
  while not heap:isEmpty() do
    local pipeSatData = heap:pop() -- get the most saturated pipe

    -- find the color with the lowest number not used by any of its neighbors
    local colorNbr = 0
    while pipeSatData:hasNeighborOfColor(colorNbr) do
      colorNbr = colorNbr + 1
    end

    -- set the pipe to that color
    pipeColors[colorNbr] = (pipeColors[colorNbr] or {})
    table.insert(pipeColors[colorNbr], pipeSatData.pipeId)

    -- tell the pipe's neighbors to change their saturation/degree, and update the heap
    for _, neighborPipeId in pairs(connectedPipes:getNeighbors(pipeSatData.pipeId)) do
      local node = heapNodes[neighborPipeId]
      node.object:addNeighborColor(colorNbr)
      heap:decreaseKey(node, node.object)
    end
  end

  return pipeColors
end

local function processAllPipes (factory)
  local batches = batchPipes(factory)

  local inventoryInfo = ItemDetailAndLimitCache.new(factory.missing)
  for _, batchedPipeIds in pairs(batches) do
    local itemPipes = {}

    for pipeId, _ in pairs(batchedPipeIds) do
      local pipe = factory.pipes[pipeId]

      if factory.groups[pipe.from].fluid then
        table.insert(pipeCoros, function () processFluidPipe(pipe, factory.groups, factory.missing) end)
      else
        table.insert(pipeCoros, function () processPipe(pipe, factory.groups, inventoryInfo) end)
        table.insert(itemPipes, pipe)
      end
    end

    inventoryInfo:FulfillPipes(itemPipes, factory.groups)
    parallel.waitForAll(unpack(pipeCoros))
  end
end

local function processAllPipesForever (factory)
  while true do
    local ok, err = pcall(function () processAllPipes(factory) end)
    if not ok then
      LOGGER:warn("pipe.lua#processAllPipesForever() caught error " .. err)
    end
    coroutine.yield()
  end
end

return {
  processAllPipesForever = processAllPipesForever,
}