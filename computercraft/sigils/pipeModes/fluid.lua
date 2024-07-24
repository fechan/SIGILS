---Get the transfer orders needed to transfer fluids from the origin fluid tanks
---to the destinations
---@param origin Group Origin fluid group to transfer from
---@param destination Group Destination fluid group to transfer to
---@param missingPeriphs table<string, boolean> Set of missing peripherals by ID
---@param filter function Filter function that accepts individual fluids returned by fluid_storage.tanks()
local function getTransferOrders (origin, destination, missingPeriphs, filter)
  local orders = {}

  for _, originSlot in ipairs(origin.slots) do
    if not missingPeriphs[originSlot.periphId] then
      for _, destSlot in ipairs(destination.slots) do
        if not missingPeriphs[destSlot.periphId] then
          table.insert(orders, {from=originSlot, to=destSlot})
        end
      end
    end
  end

  return orders
end

return {
  getTransferOrders = getTransferOrders,
}