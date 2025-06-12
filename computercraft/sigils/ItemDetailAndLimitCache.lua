local Concurrent = require('sigils.concurrent')

---A class for storing itemDetail and itemLimits of slots in slot groups
---@class ItemDetailAndLimitCache
local ItemDetailAndLimitCache = {}

local function getSlotId (slot)
  return slot.periphId .. '/' .. slot.slot
end

---Create a new ItemDetailAndLimitCache
---@param missingPeriphs table Set of missing peripheral IDs
---@param initialMap? table? Initial map of slot IDs and their item limits/details
---@return ItemDetailAndLimitCache itemDetailAndLimitCache New cache
function ItemDetailAndLimitCache.new (missingPeriphs, initialMap)
  local o = {
    map = initialMap or {},
    missingPeriphs = missingPeriphs or {},
  }

  ---Return true if the slot is connected to the network
  ---(i.e. its peripheral is not missing)
  ---@param slot Slot slot to check for
  ---@return boolean isConnected True if connected
  function o:slotConnected (slot)
    return not o.missingPeriphs[slot.periphId]
  end

  ---Fulfills the item details for each slot in the given groups in parallel
  ---@param groups Group[] List of groups to fulfill item limits and details for
  ---@param forceDetail boolean True if item details should be requested even if cached
  function o:Fulfill(groups, forceDetail)
    local runner = Concurrent.default_runner

    for _, group in pairs(groups) do
      for _, slot in pairs(group.slots) do
        if o:slotConnected(slot) then
          -- make a itemDetail and itemLimit data structure in the map for the slot if it's not there already
          local slotId = getSlotId(slot)
          if o.map[slotId] == nil then
            o.map[slotId] = {}
          end

          -- fulfill itemDetail
          if forceDetail or o.map[slotId].itemDetail == nil then
            runner.spawn(
              function ()
                local periph = peripheral.wrap(slot.periphId)
                if periph then
                  local getItemDetail = periph.getItemDetail or periph.getItemMeta
                  o.map[slotId].itemDetail = getItemDetail(slot.slot)
                end
              end
            )
          end

          -- fulfill itemLimit
          if o.map[slotId].itemLimit == nil then
            runner.spawn(
              function ()
                local periph = peripheral.wrap(slot.periphId)
                if periph then
                  local getItemLimit = periph.getItemLimit or function () return 64 end
                  o.map[slotId].itemLimit = getItemLimit(slot.slot)
                end
              end
            )
          end
        end
      end
    end

    runner.run_until_done()
  end

  ---Fulfills the item details for all groups that are the origin or destination
  ---of a set of pipes
  ---
  ---NOTE: This function will try to fulfill the same slot multiple times if
  ---there are any pipes passed in that operate on the same groups, which isn't
  ---efficient. For now, this doesn't matter because the only place this cache
  ---is needed is running the pipes, which are separated via the edge coloring
  ---algo.
  ---@param pipes Pipe[] Array of pipes whose origin/destinations groups should be fulfilled
  ---@param groupMap table<string, Group> Maps Group IDs to Groups in the factory
  ---@param forceDetail boolean True if item details should be requested even if cached
  function o:FulfillPipes (pipes, groupMap, forceDetail)
    local groups = {}
    for _, pipe in pairs(pipes) do
      table.insert(groups, groupMap[pipe.from])
      table.insert(groups, groupMap[pipe.to])
    end
    o:Fulfill(groups, forceDetail)
  end

  ---Get the item limit of the given Slot
  ---(This is max number of items holdable by the slot, regardless of whether
  ---an item is in the slot)
  ---@param slot Slot Slot to get item limit for
  ---@return number itemLimit Slot item limit
  function o:GetItemLimit (slot)
    return o.map[getSlotId(slot)].itemLimit
  end

  ---Get the item detail of the given Slot, or nil if there's nothing in the Slot
  ---@param slot Slot Slot to get item details for
  ---@return table itemDetail Item details in slot
  function o:GetItemDetail (slot)
    return o.map[getSlotId(slot)].itemDetail
  end

  ---Get a Group's empty slots
  ---@param group Group Group to get empty slots of
  ---@return Slot[] emptySlots List of empty slots
  function o:GetEmptySlots (group)
    local emptySlots = {}

    for _, slot in pairs(group.slots) do
      if o:slotConnected(slot) and o:GetItemDetail(slot) == nil then
        table.insert(emptySlots, slot)
      end
    end

    return emptySlots
  end

  ---Get slots in the given Group that match the filter.
  ---@param group Group Group to check for matching slots
  ---@param filter function Filter function accepting item details
  ---@return Slot[] matchingSlots Slots with matching items
  function o:GetSlotsWithMatchingItems (group, filter)
    local matchingSlots = {}

    for _, slot in pairs(group.slots) do
      if o:slotConnected(slot) then
        local itemDetail = o:GetItemDetail(slot)
        if itemDetail and filter(itemDetail) then
          table.insert(matchingSlots, slot)
        end
      end
    end

    return matchingSlots
  end

  ---Get the number of items in the given slot
  ---@param slot Slot Slot to get number of items in
  ---@return number count Number of items in the slot
  function o:GetNumExistingItemsAt (slot)
    local itemDetail = o:GetItemDetail(slot)
    if itemDetail then
      return itemDetail.count
    end
    return 0
  end

  return o
end

return ItemDetailAndLimitCache