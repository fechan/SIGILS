---A class for tracking which peripherals are connected or missing
---@class ConnectedPeriphs
local ConnectedPeriphs = {}

function ConnectedPeriphs.new()
  local o = {
    ---Manifest of all connected peripherals
    periphs = {},
    ---Set of peripheral IDs that are in the factory but not connected
    missing = {},
  }

  function o:updateAll(factory)
    o:updatePeriphs()
    o:updateMissing(factory)
  end

  function o:updatePeriphs()
    o.periphs = {}

    local allConnected = peripheral.getNames()
    for _, periphId in pairs(allConnected) do
      local periph = peripheral.wrap(periphId)
      local periphDescriptor = {size = 0, fluidTanks = 0}

      if periph.pushItems then
        periphSize.size = periphSize()
      end
      if periph.tanks then
        periphSize.fluidTanks = #(periph.tanks())
      end

      if periphDescriptor.size > 0 or periphDescriptor.fluidTanks > 0 then
        o.periphs[periphId] = periphDescriptor
      end
    end
  end

  function o:updateMissing(factory)
    o.missing = {}
    local periphsInFactorySet = {}

    for _, group in pairs(factory.groups) do
      for _, slot in pairs(group.slots) do
        if o.periphs[slot.periphId] == nil then
          o.missing[slot.periphId] = true
        end
      end
    end
  end

  return o
end

return ConnectedPeriphs