local Utils = require('utils')

---CC: Tweaked WebSocket handle (https://tweaked.cc/module/http.html#ty:Websocket)
---@class Websocket

-- This is a table with message type names as keys and not an array
-- so it's easy to check if a string is in the list of message types
local MESSAGE_TYPES = {
  BatchRequest = true,
  ConfirmationResponse = true,
  SessionCreate = true,
  SessionJoin = true,
  FactoryGet = true,
  FactoryGetResponse = true,
  PipeAdd = true,
  PipeEdit = true,
  PipeDel = true,
  MachineAdd = true,
  MachineEdit = true,
  MachineDel = true,
  GroupAdd = true,
  GroupEdit = true,
  GroupDel = true,
}

---Request a session from the editor session server once
---@param ws Websocket ComputerCraft Websocket handle
---@return table response ConfirmationResponse as a Lua table
---@return string sessionId Session ID requested
local function requestSessionOnce (ws)
  local sessionId = Utils.randomString(4)
  local req = {
    type = 'SessionCreate',
    reqId = Utils.randomString(20),
    sessionId = sessionId,
  }
  ws.send(textutils.serializeJSON(req))

  local res = ws.receive(5)
  return textutils.unserializeJSON(res), sessionId
end

---Connect to the editor session server and request a session, retrying if needed
---@param wsContext table Shared WebSocket context
---@param maxAttempts number Max attempts to connect and get a session
---@return boolean ok True if session was acquired, false otherwise
local function connectAndRequestSession (wsContext, maxAttempts)
  local attempts = 1

  local ws, err = http.websocket(wsContext.wsUrl)
  while not ws do
    if attempts > maxAttempts then
      print('Failed to connect to editor session server... pipes will continue to run but you cannot edit them.')
      print('Reason:', err)
      return false
    end

    print('Trying to connect. Attempt', attempts)
    os.sleep(3)
    ws, err = http.websocket(wsContext.wsUrl)
    attempts = attempts + 1
  end
  wsContext.ws = ws

  local res, sessionId = requestSessionOnce(ws)
  while res == nil or not res.ok do
    if attempts > maxAttempts then
      print('Failed to create session for editor... pipes will continue to run but you cannot edit them.')
      print('Reason:', (res and res.message) or 'received empty response after requesting session.')
      return false
    end
    print('Trying to create session. Attempt', attempts)
    res, sessionId = requestSessionOnce(ws)
    attempts = attempts + 1
  end

  print()
  print('Connection to editor server successful!')
  print('Press E again to end the session.')
  print('Insert code', sessionId, 'into web editor to edit pipes.')
  return true
end

---Queue an OS event for a given message. The event name will always be in the
---format `ccpipes-{message.type}` and have the message body as its data.
---
---The purpose of this is to notify the factory controller of user edits.
---@param message table Any message from the session server
local function queueEventFromMessage (message)
  local messageType = message['type']

  if MESSAGE_TYPES[messageType] then
    os.queueEvent('ccpipes-' .. messageType, message)
  elseif messageType == 'IdleTimeout' then
    print('Disconnected due to idling: ' .. message['message'])
  else
    print('Unhandled message type in websocket.lua: ' .. messageType)
  end
end

---Start the WebSocket runner.
---The runner has three states:
--- * WAIT-FOR-USER: Wait for the user to press `E` to enter the START-CONNECT state
--- * START-CONNECT: Attempt to connect to the editor session server.
---                  Will enter CONNECTED on success or WAIT-FOR-USER on fail.
--- * CONNECTED: Wait for messages from WS server and dispatch events for the controller.
---              Will enter WAIT-FOR-USER on disconnect or fail.
---@param wsContext table Shared WebSocket context
local function doWebSocket (wsContext)
  local state = 'WAIT-FOR-USER'

  print('Press E to create a factory editing session.')
  while true do
    if state == 'WAIT-FOR-USER' then
      local event, char = os.pullEvent('char')
      if char == 'e' then
        state = 'START-CONNECT'
      end
    elseif state == 'START-CONNECT' then
      local established = connectAndRequestSession(wsContext, 5)
      if established then
        state = 'CONNECTED'
      else
        print()
        print(
          'Press E to try to create a factory editing session again ' ..
          'or press Q to stop all pipes and quit.'
        )
        state = 'WAIT-FOR-USER'
      end
    elseif state == 'CONNECTED' then
      local listenForMessage = (function ()
        local ok, res, isBinary = pcall(function () return wsContext.ws.receive() end)
        if not ok then
          print()
          print('Lost connection to editor session server.')
          print('Press E to try to create a factory editing session again.')
          state = 'WAIT-FOR-USER'
        elseif res ~= nil and not isBinary then
          queueEventFromMessage(textutils.unserializeJSON(res))
        end
      end)
      local listenForStopEditingKey = (function ()
        local event, char = os.pullEvent('char')
        if char == 'e' then
          print()
          print(
            'Editor session closed. Press E to create a new editing session ' ..
            'or press Q to stop all pipes and quit.'
          )
          wsContext.ws.close()
          wsContext.ws = nil
          state = 'WAIT-FOR-USER'
        end
      end)
      while state == 'CONNECTED' do
        parallel.waitForAny(listenForMessage, listenForStopEditingKey)
      end
    end
  end
end

return {
  doWebSocket = doWebSocket,
}