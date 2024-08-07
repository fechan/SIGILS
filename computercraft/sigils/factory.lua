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
---@return table diffs List of jsondiffpatch Deltas for the factory
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
---@return table diffs List of jsondiffpatch Deltas for the factory
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
---@return table diffs List of jsondiffpatch Deltas for the factory
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
---@return table diffs List of jsondiffpatch Deltas for the factory
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
---@param machineId? string ID of machine to add the group to. If provided, the group ID will be added to the machine's group list.
---@return table diffs List of jsondiffpatch Deltas for the factory
local function groupAdd (factory, group, machineId)
  local diff = {
    groups = {
      [group.id] = {group}
    }
  }

  factory.groups[group.id] = group

  if machineId then
    local machineUpdatedGroups = Utils.shallowCopy(factory.machines[machineId].groups)
    table.insert(machineUpdatedGroups, group.id)

    return Utils.concatArrays(
      {diff},
      machineEdit(factory, machineId, { groups=machineUpdatedGroups })
    )
  end

  return {diff}
end

---Delete a machine from the factory
---@param factory Factory Factory to delete from
---@param machineId string ID of the machine to delete
---@return table diffs List of jsondiffpatch Deltas for the factory
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

---Delete a group from the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to remove
---@return table diffs List of jsondiffpatch Deltas for the factory
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
  local machineUpdates = {}
  for machineId, machine in pairs(factory.machines) do
    for groupIdxInMachine, groupIdInMachine in ipairs(machine.groups) do
      if groupIdInMachine == groupId then
        table.remove(machine.groups, groupIdxInMachine)
        if #machine.groups == 0 then
          table.insert(machineUpdates, machineDel(factory, machineId))
        else
          table.insert(machineUpdates, machineEdit(factory, machineId, { groups = machine.groups }))
        end
        break
      end
    end

    if #machineUpdates > 0 then
      break
    end
  end
  machineUpdates = Utils.concatArrays(unpack(machineUpdates))

  return Utils.concatArrays(
    {diff},
    pipeDels,
    machineUpdates
  )
end

---Edit a group in the factory
---@param factory Factory Factory the group is in
---@param groupId string ID of group to edit
---@param edits table Map of keys to edit -> new values
---@return table diffs List of jsondiffpatch Deltas for the factory
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

---Add a peripheral to the missing peripherals set
---@param factory Factory Factory to add to
---@param periphId string CC Peripheral ID
---@param skipPresenceCheck? boolean Whether to skip checking for if the periphId is already in the factory
---@return table diffs List of jsondiffpatch Deltas for the factory
local function missingAdd (factory, periphId, skipPresenceCheck)
  if skipPresenceCheck then
    factory.missing[periphId] = true

    local diff = {
      missing = {
        [periphId] = {true}
      }
    }
    return {diff}
  end

  -- try to find periphId in the factory. if it's not there, it doesn't matter
  -- if it's missing, so we don't change anything.
  for _, group in pairs(factory.groups) do
    for _, slot in pairs(group.slots) do
      if periphId == slot.periphId then
        factory.missing[periphId] = true

        local diff = {
          missing = {
            [periphId] = {true}
          }
        }
        return {diff}
      end
    end
  end

  return {}
end

---Delete a peripheral from the missing peripherals set
---@param factory Factory Factory to delete from to
---@param periphId string CC Peripheral ID
---@return table diffs List of jsondiffpatch Deltas for the factory
local function missingDel (factory, periphId)
  factory.missing[periphId] = nil

  local diff = {
    missing = {
      [periphId] = {
        nil, 0, 0
      }
    }
  }
  return {diff}
end

---Add a peripheral to the available peripherals set
---@param factory Factory Factory to add to
---@param periphId string CC Peripheral ID
---@param skipPresenceCheck? boolean Whether to skip checking for if the periphId is already in the factory
---@return table diffs List of jsondiffpatch Deltas for the factory
local function availableAdd (factory, periphId, skipPresenceCheck)
  -- try to find periphId in the factory. if it's there, it doesn't matter
  -- because it's in a machine already, so we don't change anything.\
  if not skipPresenceCheck then
    for _, group in pairs(factory.groups) do
      for _, slot in pairs(group.slots) do
        if periphId == slot.periphId then
          return {}
        end
      end
    end
  end

  factory.available[periphId] = true

  local diff = {
    available = {
      [periphId] = {true}
    }
  }
  return {diff}
end

---Delete a peripheral from the available peripherals set
---@param factory Factory Factory to delete from to
---@param periphId string CC Peripheral ID
---@return table diffs List of jsondiffpatch Deltas for the factory
local function availableDel (factory, periphId)
  factory.available[periphId] = nil

  local diff = {
    available = {
      [periphId] = {
        nil, 0, 0
      }
    }
  }
  return {diff}
end

---Add a peripheral to the factory as a new machine
---@param factory Factory Factory to add the peripheral to
---@param periphId string Peripheral to add
---@param initialOptions table? Options to initialize the machine with
---@return table diffs List of jsondiffpatch Deltas for the factory
local function periphAdd (factory, periphId, initialOptions)
  local newMachine, newGroups = Machine.fromPeriphId(periphId)

  for option, v in pairs(initialOptions) do
    newMachine[option] = v
  end

  local periphAttachDiffs = {}

  if factory.available[periphId] then
    table.insert(periphAttachDiffs, availableDel(factory, periphId))
  end

  local machineAddDiff = machineAdd(factory, newMachine)
  machineAddDiff = Utils.freezeTable(machineAddDiff)
  table.insert(periphAttachDiffs, machineAddDiff)

  for groupId, group in pairs(newGroups) do
    local groupAddDiff = groupAdd(factory, group)
    groupAddDiff = Utils.freezeTable(groupAddDiff)
    table.insert(periphAttachDiffs, groupAddDiff)
  end

  return Utils.concatArrays(unpack(periphAttachDiffs))
end

---Remove a peripheral's slots from all groups in the factory.
---
---If any groups are empty after the peripheral is removed, the group is removed
---as well.
---@param factory Factory Factory to remove from
---@param periphId string CC peripheral ID
---@return table diffs List of jsondiffpatch Deltas for the factory
local function periphDel (factory, periphId)
  local diffs = {}

  if factory.missing[periphId] then
    table.insert(diffs, missingDel(factory, periphId))
  end

  for groupId, group in pairs(factory.groups) do
    local numSlots = #group.slots
    local keptSlots = {}
    for i, slot in ipairs(group.slots) do
      if slot.periphId ~= periphId then
        table.insert(keptSlots, slot)
      end
    end

    if #keptSlots == 0 then
      local groupDelDiff = groupDel(factory, groupId)
      table.insert(diffs, Utils.freezeTable(groupDelDiff))
    elseif numSlots ~= #keptSlots then
      local groupEditDiff = groupEdit(factory, groupId, { slots = keptSlots })
      table.insert(diffs, Utils.freezeTable(groupEditDiff))
    end
  end

  return Utils.concatArrays(unpack(diffs))
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

---Get the list of peripheral IDs that are represented in the factory
---@param factory Factory Factory containing peripherals
---@return table periphs List of peripheral IDs represented in the factory
local function getPeripheralIdsInFactory (factory)
  local periphs = {}
  for groupId, group in pairs(factory.groups) do
    for i, slot in ipairs(group.slots) do
      periphs[slot.periphId] = true
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

---Given an existing factory, add peripherals that are no longer on the network
---to the missing peripheral set and add newly added peripherals to the
---available peripheral set.
---@param factory Factory Factory to update with peripheral changes
local function updateWithPeriphChanges (factory)
  local diffs = {}

  local currentPeriphSet = {}
  for i, periphId in ipairs(getPeripheralIds()) do
    currentPeriphSet[periphId] = true
  end

  local oldPeriphSet = getPeripheralIdsInFactory(factory)

  -- put disconnected peripherals in missing:
  -- (any periphId in oldPeriphSet that's not in currentPeriphSet goes into missing)
  for oldPeriphId, _ in pairs(oldPeriphSet) do
    if currentPeriphSet[oldPeriphId] == nil then
      table.insert(diffs, missingAdd(factory, oldPeriphId, true))
    end
  end

  -- put newly connected peripherals in available
  -- (any periphId in currentPeriphSet that's not in oldPeriphSet goes into available)
  for currentPeriphId, _ in pairs(currentPeriphSet) do
    if oldPeriphSet[currentPeriphId] == nil then
      table.insert(diffs, availableAdd(factory, currentPeriphId, true))
    end
  end

  -- remove peripherals from missing peripheral list are connected now
  for periphId, _ in pairs(factory.missing) do
    if currentPeriphSet[periphId] then
      table.insert(diffs, missingDel(factory, periphId))
    end
  end

  -- remove peripherals from available peripheral list that are not longer connected
  for periphId, _ in pairs(factory.available) do
    if currentPeriphSet[periphId] == nil then
      table.insert(diffs, availableDel(factory, periphId))
    end
  end

  return Utils.concatArrays(unpack(diffs))
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
  periphAdd = periphAdd,
  periphDel = periphDel,
  missingAdd = missingAdd,
  missingDel = missingDel,
  availableAdd = availableAdd,
  availableDel = availableDel,
  autodetectFactory = autodetectFactory,
  updateWithPeriphChanges = updateWithPeriphChanges,
  saveFactory = saveFactory,
}