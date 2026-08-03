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

local function handleFactoryPut (request, factory, sendMessage)
  factory.pipes = request.factory.pipes -- TODO: make this actually replace the factory object??
  factory.machines = request.factory.machines
  factory.groups = request.factory.groups
end

local function handlePipeAdd (request, factory, sendMessage)
  Factory.pipeAdd(factory, request.pipe)
  return true
end

local function handlePipeDel (request, factory, sendMessage)
  Factory.pipeDel(factory, request.pipeId)
  return true
end

local function handlePipeEdit (request, factory, sendMessage)
  Factory.pipeEdit(factory, request.pipeId, request.edits)
  return true
end

local function handleMachineAdd (request, factory, sendMessage)
  Factory.machineAdd(factory, request.machine)
  return true
end

local function handleMachineDel (request, factory, sendMessage)
  Factory.machineDel(factory, request.machineId)
  return true
end

local function handleMachineEdit (request, factory, sendMessage)
  Factory.machineEdit(factory, request.machineId, request.edits)
  return true
end

local function handleGroupAdd (request, factory, sendMessage)
  Factory.groupAdd(factory, request.group, request.machineId)
  return true
end

local function handleGroupDel (request, factory, sendMessage)
  Factory.groupDel(factory, request.groupId)
  return true
end

local function handleGroupEdit (request, factory, sendMessage)
  Factory.groupEdit(factory, request.groupId, request.edits)
  return true
end

local function createConfirmationResponse(request, ok, factory)
  return {
    type = 'ConfirmationResponse',
    respondingTo = request.type,
    reqId = request.reqId,
    ok = ok,
    factory = factory,
  }
end

local function handlePeripheralAttach(periphId, factory, connectedPeriphs, sendMessage)
  connectedPeriphs:updateAll(factory)

  sendMessage(textutils.serializeJSON{
    type = "CcUpdatedPeriphs",
    periphs = connectedPeriphs.periphs
  })

  return false
end

local function handlePeripheralDetach(periphId, factory, connectedPeriphs, sendMessage)
  connectedPeriphs:updateAll(factory)

  sendMessage(textutils.serializeJSON{
    type = "CcUpdatedPeriphs",
    periphs = connectedPeriphs.periphs
  })

  return false
end

---Forever listens for events that require a factory update, and sends
---WebSocket messages to the client to inform it of the changes, if the channel
---is available
local function listenForCcpipesEvents (wsContext, factory, connectedPeriphs)

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
      ['ccpipes-FactoryPut'] = handleFactoryPut,
      ['ccpipes-PipeAdd'] = handlePipeAdd,
      ['ccpipes-PipeDel'] = handlePipeDel,
      ['ccpipes-PipeEdit'] = handlePipeEdit,
      ['ccpipes-MachineAdd'] = handleMachineAdd,
      ['ccpipes-MachineDel'] = handleMachineDel,
      ['ccpipes-MachineEdit'] = handleMachineEdit,
      ['ccpipes-GroupAdd'] = handleGroupAdd,
      ['ccpipes-GroupDel'] = handleGroupDel,
      ['ccpipes-GroupEdit'] = handleGroupEdit,
    }

    if event == 'ccpipes-BatchRequest' then
      for i, request in pairs(message.requests) do
        local handlerName = 'ccpipes-' .. request.type
        if handlers[handlerName] then
          handlers[handlerName](request, factory, sendMessage)
        end
      end
      sendMessage(textutils.serializeJSON(createConfirmationResponse(message, true, factory)))
    elseif handlers[event] then
      local factoryChanged = handlers[event](message, factory, sendMessage)
      if factoryChanged then
        sendMessage(textutils.serializeJSON(createConfirmationResponse(message, true, factory)))
      end
    elseif event == 'peripheral' then
      handlePeripheralAttach(message, factory, connectedPeriphs, sendMessage)
    elseif event == 'peripheral_detach' then
      handlePeripheralDetach(message, factory, connectedPeriphs, sendMessage)
    end

    if (handlers[event] or event == 'ccpipes-BatchRequest' or event == 'peripheral' or event == 'peripheral_detach') and event ~= 'ccpipes-FactoryGet' then
      Factory.saveFactory(factory)
    end
  end
end

return {
  listenForCcpipesEvents = listenForCcpipesEvents,
}