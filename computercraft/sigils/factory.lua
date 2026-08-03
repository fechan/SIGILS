--- factory.lua: Functions for modifying the factory data structure (in place)
local Machine = require('sigils.machine')
local Utils = require('sigils.utils')

---A data structure for a Factory matching `/server/src/types/core-types.ts#Factory`
---@class Factory

---A data structure for a Machine matching `/server/src/types/core-types.ts#Machine`
---@class Machine

---A data structure for a Group matching `/server/src/types/core-types.ts#Group`
---@class Group

---Save a factory as a JSON file
---@param factory Factory Factory to save
local function saveFactory(factory)
  local json = textutils.serializeJSON(factory)
  local f = fs.open(Utils.absolutePathTo('factory.json'), 'w')
  f.write(json)
  f.close()
end

---Add a pipe to a factory
---@param factory Factory Factory to add to
---@param pipe Pipe Pipe to add
local function pipeAdd (factory, pipe)
  factory.pipes[pipe.id] = pipe
end

---Delete a pipe from the factory
---@param factory Factory Factory to delete from
---@param pipeId string ID of pipe to remove
local function pipeDel (factory, pipeId)
  factory.pipes[pipeId] = nil
end

---Edit a pipe in the factory
---@param factory Factory Factory the pipe is in
---@param pipeId string ID of pipe to edit
---@param edits table Map of keys to edit -> new values
local function pipeEdit (factory, pipeId, edits)
  local pipe = factory.pipes[pipeId]

  for k, v in pairs(edits) do
    pipe[k] = v
  end
end


---Edit a machine in the factory
---@param factory Factory Factory the machine is in
---@param machineId string ID of machine to edit
---@param edits table Map of keys to edit -> new values
local function machineEdit (factory, machineId, edits)
  local machine = factory.machines[machineId]

  for k, v in pairs(edits) do
    machine[k] = v
  end
end

---Add a newly created group to a machine in the factory
---@param factory Factory Factory the machine is in
---@param group Group New group to add
---@param machineId? string ID of machine to add the group to. If provided, the group ID will be added to the machine's group list.
local function groupAdd (factory, group, machineId)
  factory.groups[group.id] = group

  if machineId then
    local machineUpdatedGroups = Utils.shallowCopy(factory.machines[machineId].groups)
    table.insert(machineUpdatedGroups, group.id)
    machineEdit(factory, machineId, { groups=machineUpdatedGroups })
  end
end

---Delete a machine from the factory
---@param factory Factory Factory to delete from
---@param machineId string ID of the machine to delete
local function machineDel (factory, machineId)
  factory.machines[machineId] = nil
end

---Delete a group from the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to remove
local function groupDel (factory, groupId)
  local oldGroup = factory.groups[groupId]
  factory.groups[groupId] = nil

  -- delete all pipes that have this group at either end
  for pipeId, pipe in pairs(factory.pipes) do
    if pipe.from == groupId or pipe.to == groupId then
      pipeDel(factory, pipeId)
    end
  end

  -- find the machine that had the group in it and remove the group from it
  local machineFound = false
  for machineId, machine in pairs(factory.machines) do
    for groupIdxInMachine, groupIdInMachine in ipairs(machine.groups) do
      if groupIdInMachine == groupId then
        table.remove(machine.groups, groupIdxInMachine)
        if #machine.groups == 0 then
          machineDel(factory, machineId)
        else
          machineEdit(factory, machineId, { groups = machine.groups })
        end

        machineFound = true
        break
      end
    end

    if machineFound then
      break
    end
  end
end

---Edit a group in the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to edit
---@param edits table Map of keys to edit -> new values
local function groupEdit (factory, groupId, edits)
  local group = factory.groups[groupId]

  for k, v in pairs(edits) do
    group[k] = v
  end
end

---Add a machine to a factory
---@param factory Factory Factory to add to
---@param machine Machine Machine to add
---@return table diffs List of jsondiffpatch Deltas for the factory
local function machineAdd (factory, machine)
  factory.machines[machine.id] = machine

  local diff = {
    machines = {
      [machine.id] = {machine}
    }
  }
  return {diff}
end

---Get peripheral IDs connected to the network
---@return string[] periphs List of peripheral IDs
local function getPeripheralIds ()
  local periphs = {}
  for i, periphId in ipairs(peripheral.getNames()) do
    -- add if the peripheral has an inventory and is connected via a modem
    local periph = peripheral.wrap(periphId)

    local isInventory = periph['pushItems'] ~= nil and periph.size() >= 1
    local isFluidTank = periph['tanks'] ~= nil

    if isInventory or isFluidTank then
      table.insert(periphs, periphId)
    end
  end
  return periphs
end

---Autodetect peripherals and generate a Factory
---@return Factory factory Factory with autodetected peripherals
local function autodetectFactory ()
  local factory = {
    machines = {},
    groups = {},
    pipes = {},
    missing = {},
    available = {},
  }
  for i, periphId in ipairs(getPeripheralIds()) do
    local machine, groups = Machine.fromPeriphId(periphId)
    if machine then
      factory.machines[machine.id] = machine

      for groupId, group in pairs(groups) do
        factory.groups[groupId] = group
      end
    end
  end

  return factory
end

return {
  pipeAdd = pipeAdd,
  pipeDel = pipeDel,
  pipeEdit = pipeEdit,
  machineAdd = machineAdd,
  machineDel = machineDel,
  machineEdit = machineEdit,
  groupAdd = groupAdd,
  groupDel = groupDel,
  groupEdit = groupEdit,
  autodetectFactory = autodetectFactory,
  saveFactory = saveFactory,
}