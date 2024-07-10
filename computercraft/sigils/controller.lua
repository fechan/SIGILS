local Factory = require('sigils.factory')
local Utils   = require('sigils.utils')
local LOGGER  = require('sigils.logging').LOGGER

local function handleFactoryGet (request, factory, sendMessage)
  local factoryGetRes = {
    type = 'ConfirmationResponse',
    respondingTo = 'FactoryGet',
    reqId = request.reqId,
    ok = true,
    factory = factory,
  }
  sendMessage(textutils.serializeJSON(factoryGetRes))
end

local function handlePipeAdd (request, factory, sendMessage)
  local pipe = request.pipe
  local diff = Factory.pipeAdd(factory, pipe)
  return diff
end

local function handlePipeDel (request, factory, sendMessage)
  local pipeId = request.pipeId
  local diff = Factory.pipeDel(factory, pipeId)
  return diff
end

local function handlePipeEdit (request, factory, sendMessage)
  local diff = Factory.pipeEdit(factory, request.pipeId, request.edits)
  return diff
end

local function handleMachineAdd (request, factory, sendMessage)
  local machine = request.machine
  local diff = Factory.machineAdd(factory, machine)
  return diff
end

local function handleMachineDel (request, factory, sendMessage)
  local diff = Factory.machineDel(factory, request.machineId)
  return diff
end

local function handleMachineEdit (request, factory, sendMessage)
  local diff = Factory.machineEdit(factory, request.machineId, request.edits)
  return diff
end

local function handleGroupAdd (request, factory, sendMessage)
  local diff = Factory.groupAdd(factory, request.group, request.machineId)
  return diff
end

local function handleGroupDel (request, factory, sendMessage)
  local diff = Factory.groupDel(factory, request.groupId)
  return diff
end

local function handleGroupEdit (request, factory, sendMessage)
  local diff = Factory.groupEdit(factory, request.groupId, request.edits)
  return diff
end

local function handlePeriphAdd(request, factory, sendMessage)
  local diff = Factory.periphAdd(factory, request.periphId, request.options)
  return diff
end

local function handlePeriphDel(request, factory, sengMessage)
  local diff = Factory.periphDel(factory, request.periphId)
  return diff
end

local function createConfirmationResponse(request, ok, diff)
  return {
    type = 'ConfirmationResponse',
    respondingTo = request.type,
    reqId = request.reqId,
    ok = ok,
    diff = diff
  }
end

local function handlePeripheralAttach(periphId, factory, sendMessage)
  local diff = Factory.updateWithPeriphChanges(factory)
  if #diff == 0 then return end

  sendMessage(textutils.serializeJSON({
    type = "CcUpdatedFactory",
    diff = diff
  }))
end

local function handlePeripheralDetach(periphId, factory, sendMessage)
  local diff = Factory.updateWithPeriphChanges(factory)
  if #diff == 0 then return end

  sendMessage(textutils.serializeJSON({
    type = "CcUpdatedFactory",
    diff = diff
  }))
end

---Forever listens for events that require a factory update, and sends
---WebSocket messages to the client to inform it of the changes, if the channel
---is available
local function listenForCcpipesEvents (wsContext, factory)

  ---This function safely wraps the WebSocket send function so SIGILS doesn't crash
  ---if the WebSocket is closed. The function signature is identical to
  ---Websocket.send https://tweaked.cc/module/http.html#ty:Websocket:send
  local sendMessage = function (message, binary)
    if wsContext.ws then
      local ok, err = pcall(function () wsContext.ws.send(message, binary) end)
      if not ok then
        LOGGER:error('Error while sending WebSocket message: ' .. err)
      end
    else
      LOGGER:warn('Attempted to send a WebSocket message on a closed channel.')
    end
  end

  while true do
    local event, message = os.pullEvent()

    local handlers = {
      ['ccpipes-FactoryGet'] = handleFactoryGet,
      ['ccpipes-PipeAdd'] = handlePipeAdd,
      ['ccpipes-PipeDel'] = handlePipeDel,
      ['ccpipes-PipeEdit'] = handlePipeEdit,
      ['ccpipes-MachineAdd'] = handleMachineAdd,
      ['ccpipes-MachineDel'] = handleMachineDel,
      ['ccpipes-MachineEdit'] = handleMachineEdit,
      ['ccpipes-GroupAdd'] = handleGroupAdd,
      ['ccpipes-GroupDel'] = handleGroupDel,
      ['ccpipes-GroupEdit'] = handleGroupEdit,
      ['ccpipes-PeriphAdd'] = handlePeriphAdd,
      ['ccpipes-PeriphDel'] = handlePeriphDel,
    }

    if event == 'ccpipes-BatchRequest' then
      local diffs = {}
      for i, request in pairs(message.requests) do
        local handlerName = 'ccpipes-' .. request.type
        if handlers[handlerName] then
          local diff = Utils.freezeTable(handlers[handlerName](request, factory, sendMessage))
          if (diff ~= nil) then
            table.insert(diffs, diff)
          end
        end
      end
      diffs = Utils.concatArrays(unpack(diffs))
      sendMessage(textutils.serializeJSON(createConfirmationResponse(message, true, diffs)))
    elseif handlers[event] then
      local diff = handlers[event](message, factory, sendMessage)
      if (diff ~= nil) then
        sendMessage(textutils.serializeJSON(createConfirmationResponse(message, true, diff)))
      end
    elseif event == 'peripheral' then
      handlePeripheralAttach(message, factory, sendMessage)
    elseif event == 'peripheral_detach' then
      handlePeripheralDetach(message, factory, sendMessage)
    end

    if (handlers[event] or event == 'ccpipes-BatchRequest' or event == 'peripheral' or event == 'peripheral_detach') and event ~= 'ccpipes-FactoryGet' then
      Factory.saveFactory(factory)
    end
  end
end

return {
  listenForCcpipesEvents = listenForCcpipesEvents,
}