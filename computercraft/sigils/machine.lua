---machine.lua: Functions for initializing Machines

---A data structure for a machine with slot groups matching `/server/src/types/core-types.ts#Machine`
---@class Machine

---A data structure for a group of slots matching `/server/src/types/core-types.ts#Group`
---@class Group

---A data structure for an inventory slot on a peripheral matching `/server/src/types/core-types.ts#Group`
---@class Slot

local machineTemplates = {
  require('sigils.machines.chest'),
  require('sigils.machines.generic'),
  require('sigils.machines.fluidtank'),
}

local function addFluidTank (machine, periphId, groups)
  local groupId = periphId .. ':fluids'
  local fluidGroup = {
    id = groupId,
    slots = {
      {
        periphId = periphId,
        slot = nil,
      }
    },
    nickname = 'Fluid tank',
    fluid = true,
  }

  groups[groupId] = fluidGroup
  table.insert(machine.groups, groupId)
end

---Initialize a new Machine from the given peripheral ID
---@param periphId string Peripheral ID to initialize as a Machine
---@return Machine|nil machine Newly initialized Machine
---@return Group[]|nil groups Newly initialized Groups in the Machine
local function fromPeriphId (periphId)
  for _, template in pairs(machineTemplates) do
    if template.canInitialize(periphId) then
      local machine, groups = template.initialize(periphId)

      if peripheral.wrap(periphId).tanks then
        addFluidTank(machine, periphId, groups)
      end

      return machine, groups
    end
  end
end

return {
  fromPeriphId = fromPeriphId,
}