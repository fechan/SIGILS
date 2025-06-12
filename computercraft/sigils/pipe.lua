--- pipe.lua: Functions for making pipes in the factory actually
--- transfer items

---A data structure for a Pipe matching `/server/src/types/core-types.ts#Pipe`
---@class Pipe

local ItemDetailAndLimitCache = require('sigils.ItemDetailAndLimitCache')
local PipeModeFluid = require('sigils.pipeModes.fluid')
local Filter = require('sigils.filter')
local PipeBatcher = require('sigils.pipeBatcher')
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

local function processAllPipes (factory, inventoryInfo)
  local batches = PipeBatcher.batchPipes(factory)

  for _, batchedPipeIds in pairs(batches) do
    local itemPipes = {}
    local pipeCoros = {}

    for _, pipeId in pairs(batchedPipeIds) do
      local pipe = factory.pipes[pipeId]

      if factory.groups[pipe.from].fluid then
        table.insert(pipeCoros, function () processFluidPipe(pipe, factory.groups, factory.missing) end)
      else
        table.insert(pipeCoros, function () processPipe(pipe, factory.groups, inventoryInfo) end)
        table.insert(itemPipes, pipe)
      end
    end

    inventoryInfo:FulfillPipes(itemPipes, factory.groups, true)
    parallel.waitForAll(unpack(pipeCoros))
  end
end

local function processAllPipesForever (factory)
  local inventoryInfo = ItemDetailAndLimitCache.new(factory.missing)

  while true do
    local ok, err = pcall(function () processAllPipes(factory, inventoryInfo) end)
    if not ok then
      LOGGER:warn("pipe.lua#processAllPipesForever() caught error " .. err)
    end
    coroutine.yield()
  end
end

return {
  processAllPipesForever = processAllPipesForever,
}