---Determine if the peripheral can be initialized as ONLY any fluid tank
---(e.g. it has a fluid tank, and no inventory)
---@param periphId any
---@return boolean
local function canInitialize (periphId)
  local periph = peripheral.wrap(periphId)
  local isInventory = periph.size and periph.size() > 0
  return periph.tanks ~= nil and not isInventory
end

---Create a Machine for the given tank-only peripheral
---This actually initializes an empty machine; machine.lua will add the fluid
---tank after.
---@param periphId any
---@return table
---@return table
local function initialize (periphId)
  local machine = {
    id = periphId,
    groups = {},
    nickname = nil,
  }

  local groups = {}

  return machine, groups
end

return {
  canInitialize = canInitialize,
  initialize = initialize,
}