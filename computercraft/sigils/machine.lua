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
}

local function fromPeriphId (periphId)
  for _, template in pairs(machineTemplates) do
    if template.canInitialize(periphId) then
      return template.initialize(periphId)
    end
  end
end

return {
  fromPeriphId = fromPeriphId,
}