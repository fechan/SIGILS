local Concurrent = require('sigils.concurrent')

---@class ItemDetailAndLimitCache
local ItemDetailAndLimitCache = {}

local function getSlotId (slot)
  return slot.periphId .. '/' .. slot.slot
end

function ItemDetailAndLimitCache.new (initialMap)
  local o = {
    map = initialMap or {},
  }

  ---Fulfills the item details for each slot in the given groups in parallel
  ---@param groups Group[] list of groups to fulfill item limits and details for
  function o:Fulfill(groups)
    local runner = Concurrent.create_runner(64)

    for _, group in pairs(groups) do
      for _, slot in pairs(group.slots) do
        -- make a itemDetail and itemLimit data structure in the map for the slot if it's not there already
        local slotId = getSlotId(slot)
        if o.map[slotId] == nil then
          o.map[slotId] = {}
        end

        local periph = peripheral.warp(slot.periphId)

        -- fulfill itemDetail
        runner.spawn(
          function ()
            if o.map[slotId].itemDetail == nil then
              o.map[slotId].itemDetail = periph.getItemDetail(slot.slot)
            end
          end
        )

        -- fulfill itemLimit
        runner.spawn(
          function ()
            if o.map[slotId].itemDetail == nil then
              o.map[slotId].itemDetail = periph.getItemLimit(slot.slot)
            end
          end
        )
      end
    end

    runner.run_until_done()
  end

  ---Get the item limit of the given Slot
  ---(This is max number of items holdable by the slot, regardless of whether
  ---an item is in the slot)
  ---@param slot Slot Slot to get item limit for
  ---@return unknown
  function o:GetItemLimit (slot)
    return o.map[getSlotId(slot)].itemLimit
  end

  ---Get the item detail of the given Slot, or nil if there's nothing in the Slot
  ---@param slot Slot Slot to get item details for
  ---@return table ItemDetail Inventory peripheral ItemDetail objhect
  function o:GetItemDetail (slot)
    return o.map[getSlotId(slot)].itemDetail
  end

  return o
end

return ItemDetailAndLimitCache