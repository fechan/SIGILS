--- pipe.lua: Functions for making pipes in the factory actually
--- transfer items

---A data structure for a Pipe matching `/server/src/types/core-types.ts#Pipe`
---@class Pipe

local PipeModeNatural = require('sigils.pipeModes.natural')
local PipeModeFluid = require('sigils.pipeModes.fluid')
local Filter = require('sigils.filter')
local LOGGER = require('sigils.logging').LOGGER

local function processFluidPipe (pipe, groupMap, missingPeriphs, filter)
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
  if groupMap[pipe.from].fluid then
    processFluidPipe(pipe, groupMap, missingPeriphs, function () end)
    return
  end

  local filter = Filter.getFilterFn(pipe.filter)
  local ok, transferOrders = pcall(
    function ()
      return PipeModeNatural.getTransferOrders(groupMap[pipe.from], groupMap[pipe.to], missingPeriphs, filter)
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
    parallel.waitForAll(unpack(coros))
  else
    LOGGER:warn("pipe.lua#processPipe() caught error " .. transferOrders)
  end
end

local function processAllPipes (factory)
  -- build a set of pipe IDs needing processing
  local pipesToProcess = {}
  local numPipesToProcess = 0
  for pipeId,_ in pairs(factory.pipes) do
    pipesToProcess[pipeId] = true
    numPipesToProcess = numPipesToProcess + 1
  end

  local groupIdsInBatch = {} -- set of group IDs that are affected during this batch of pipe runs

  while numPipesToProcess > 0 do
    local pipeCoros = {}

    for pipeId, _ in pairs(pipesToProcess) do
      local pipe = factory.pipes[pipeId]
      if groupIdsInBatch[pipe.from] == nil and groupIdsInBatch[pipe.to] == nil then
        table.insert(pipeCoros, function ()
          processPipe(pipe, factory.groups, factory.missing)
        end)
        numPipesToProcess = numPipesToProcess - 1
        pipesToProcess[pipeId] = nil
        groupIdsInBatch[pipe.from] = true
        groupIdsInBatch[pipe.to] = true
      end
    end

    parallel.waitForAll(unpack(pipeCoros))
    groupIdsInBatch = {}
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