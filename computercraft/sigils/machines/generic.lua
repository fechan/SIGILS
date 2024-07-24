local AUTO_GROUP_NICKNAMES = {
  furnace = {'Top', 'Fuel', 'Result'},
  brewingStand = {'Bottle', 'Bottle', 'Bottle', 'Ingredient', 'Blaze Powder'},
}

---Determine if the peripheral can be initialized as a generic machine with
---an inventory.
---@param periphId string Peripheral ID to check
---@return true canInitialize Always true
local function canInitialize (periphId)
  local periph = peripheral.wrap(periphId)
  return periph.size and periph.size() > 0
end

---Create a generic Machine for the given peripheral
---The machine will have one Group for each Slot
---@param periphId any Peripheral ID to initialize as a Machine
---@return Machine machine New chest Machine
---@return Group[] groups List of groups in the Machine
local function initialize (periphId)
  local machine = {
    id = periphId,
    groups = {},
    nickname = nil,
  }

  local groups = {}

  local periph = peripheral.wrap(periphId)
  -- create 1 group for each slot
  for slotNbr=1, periph.size() do
    local slot = {
      periphId = periphId,
      slot = slotNbr,
    }

    local nicknames = {}
    if (
      (string.find(periphId, 'minecraft:') and string.find(periphId, 'furnace_')) or
      string.find(periphId, 'minecraft:smoker_')
    ) then
      nicknames = AUTO_GROUP_NICKNAMES.furnace
    elseif string.find(periphId, 'minecraft:brewing_stand_') then
      nicknames = AUTO_GROUP_NICKNAMES.brewingStand
    end

    local groupId = periphId .. ':g' .. slotNbr
    local group = {
      id = groupId,
      slots = {slot},
      nickname = nicknames[slotNbr] or ('Slot ' .. slotNbr),
    }

    groups[groupId] = group
    table.insert(machine.groups, groupId)
  end

  return machine, groups
end

return {
  canInitialize = canInitialize,
  initialize = initialize,
}