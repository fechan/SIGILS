---Determine whether the peripheral is a Chest-like machine
---@param periphId string Peripheral ID to check
---@return boolean canInitialize true if the peripheral is a Chest
local function canInitialize (periphId)
  local peripheral = peripheral.wrap(periphId)

  return not not (
    peripheral.size and
    (string.find(periphId, 'minecraft:chest_') or
    string.find(periphId, 'minecraft:trapped_chest_') or
    string.find(periphId, 'minecraft:barrel_') or
    string.find(periphId, 'minecraft:dispenser_') or
    string.find(periphId, 'minecraft:dropper_') or
    string.find(periphId, 'minecraft:hopper_') or
    (string.find(periphId, 'minecraft:') and string.find(periphId, '_shulker_box_')) or
    peripheral.size() >= 8)
  )
end

---Create a Machine for the given chest-like peripheral
---The machine will have one Group named Inventory, containing all the Slots
---@param periphId any Peripheral ID to initialize as a Machine
---@return Machine machine New chest Machine
---@return Group[] groups List of groups in the Machine
function initialize (periphId)
  local machine = {
    id = periphId,
    groups = {},
    nickname = nil,
  }

  local groups = {}

  local groupId = periphId .. ':g1'
  local group = {
    id = groupId,
    slots = {},
    nickname = 'Inventory',
  }

  local peripheral = peripheral.wrap(periphId)

  for slotNbr=1, peripheral.size() do
    local slot = {
      periphId = periphId,
      slot = slotNbr,
    }

    groups[groupId] = group
    table.insert(group.slots, slot)
  end

  table.insert(machine.groups, groupId)

  return machine, groups
end

return {
  canInitialize = canInitialize,
  initialize = initialize,
}