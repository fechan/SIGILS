--- factory.lua: Functions for modifying the factory data structure (in place)
local Machine = require('machine')
local Utils = require('utils')

---A data structure for a Factory matching `/server/src/types/core-types.ts#Factory`
---@class Factory

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

  local diff = {
    pipes = {
      [pipe.id] = {pipe}
    }
  }
  return {diff}
end

---Delete a pipe from the factory
---@param factory Factory Factory to delete from
---@param pipeId string ID of pipe to remove
local function pipeDel (factory, pipeId)
  factory.pipes[pipeId] = nil

  local diff = {
    pipes = {
      [pipeId] = {
        nil, 0, 0
      }
    }
  }
  return {diff}
end

---Edit a pipe in the factory
---@param factory Factory Factory the pipe is in
---@param pipeId string ID of pipe to edit
---@param edits table Map of keys to edit -> new values
local function pipeEdit (factory, pipeId, edits)
  local pipe = factory.pipes[pipeId]

  local diff = {
    pipes = {
      [pipeId] = {}
    }
  }

  for k, v in pairs(edits) do
    diff.pipes[pipe.id][k] = {nil, v}
    pipe[k] = v
  end

  return {diff}
end


---Edit a machine in the factory
---@param factory Factory Factory the machine is in
---@param machineId string ID of machine to edit
---@param edits table Map of keys to edit -> new values
local function machineEdit (factory, machineId, edits)
  local machine = factory.machines[machineId]

  local diff = {
    machines = {
      [machineId] = {}
    }
  }

  for k, v in pairs(edits) do
    diff.machines[machineId][k] = {
      nil,
      v
    }
    machine[k] = v
  end

  return {diff}
end

---Add a newly created group to a machine in the factory
---@param factory Factory Factory the machine is in
---@param group Group New group to add
---@param machineId string ID of machine to add the group to
local function groupAdd (factory, group, machineId)
  local diff = {
    groups = {
      [group.id] = {group}
    }
  }

  factory.groups[group.id] = group

  local machineUpdatedGroups = Utils.shallowCopy(factory.machines[machineId].groups)
  table.insert(machineUpdatedGroups, group.id)

  return Utils.concatArrays(
    {diff},
    machineEdit(factory, machineId, { groups=machineUpdatedGroups })
  )
end

---Delete a group from the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to remove
local function groupDel (factory, groupId)
  local oldGroup = factory.groups[groupId]
  factory.groups[groupId] = nil

  local diff = {
    groups = {
      [groupId] = {
        nil, 0, 0
      }
    }
  }

  -- delete all pipes that have this group at either end
  local pipeDels = {}
  for pipeId, pipe in pairs(factory.pipes) do
    if pipe.from == groupId or pipe.to == groupId then
      table.insert(pipeDels, pipeDel(factory, pipeId))
    end
  end
  pipeDels = Utils.concatArrays(unpack(pipeDels))

  -- find the machine that had the group in it and remove the group from it
  local machineEdits = {}
  for machineId, machine in pairs(factory.machines) do
    for groupIdxInMachine, groupIdInMachine in ipairs(machine.groups) do
      if groupIdInMachine == groupId then
        table.remove(machine.groups, groupIdxInMachine)
        table.insert(machineEdits, machineEdit(factory, machineId, { groups = machine.groups }))
        break
      end
    end

    if #machineEdits > 0 then
      break
    end
  end
  machineEdits = Utils.concatArrays(unpack(machineEdits))

  return Utils.concatArrays(
    {diff},
    pipeDels,
    machineEdits
  )
end

---Edit a group in the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to edit
---@param edits table Map of keys to edit -> new values
local function groupEdit (factory, groupId, edits)
  local group = factory.groups[groupId]

  local diff = {
    groups = {
      [groupId] = {}
    }
  }

  for k, v in pairs(edits) do
    diff.groups[groupId][k] = {
      nil,
      v
    }
    group[k] = v
  end

  return {diff}
end

---Delete a machine from the factory
---@param factory Factory Factory the machine is in
---@param machineId string ID of machine to remove
local function machineDel (factory, machineId)
  factory.machines[machineId] = nil

  local diff = {
    machines = {
      [machineId] = {
        nil, 0, 0
      }
    }
  }
  return {diff}
end

---Add a machine to a factory
---@param factory Factory Factory to add to
---@param machine Machine Machine to add
local function machineAdd (factory, machine)
  factory.machines[machine.id] = machine

  local diff = {
    machines = {
      [machine.id] = {machine}
    }
  }
  return {diff}
end

---Get peripheral IDs connected to this factory
---@return string[] periphs List of peripheral IDs
local function getPeripheralIds ()
  local periphs = {}
  for i, periphId in ipairs(peripheral.getNames()) do
    -- add if the peripheral has an inventory and is connected via a modem
    if peripheral.wrap(periphId)['pushItems'] and string.match(periphId, ':') then 
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
  }
  for i, periphId in ipairs(getPeripheralIds()) do
    local machine, groups = Machine.fromPeriphId(periphId)
    factory.machines[machine.id] = machine

    for groupId, group in pairs(groups) do
      factory.groups[groupId] = group
    end
  end

  return factory
end

return {
  pipeAdd = pipeAdd,
  pipeDel = pipeDel,
  pipeEdit = pipeEdit,
  machineAdd = machineAdd,
  machineEdit = machineEdit,
  machineDel = machineDel,
  groupAdd = groupAdd,
  groupEdit = groupEdit,
  groupDel = groupDel,
  autodetectFactory = autodetectFactory,
  saveFactory = saveFactory,
}