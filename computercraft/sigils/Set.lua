local Set = {}

local metatable = {
  __len = function (set)
    return set.len
  end
}

function Set.new (iterable)
  local o = {
    hashTable = iterable or {},
    len = 0,
  }

  function o:add(elem)
    if not self.hashTable[elem] then
      self.len = self.len + 1
      self.hashTable[elem] = true
    end
  end

  function o:remove(elem)
    if self.hashTable[elem] then
      self.len = self.len - 1
      self.hashTable[elem] = nil
    end
  end

  function o:toList()
    local list = {}
    for elem, v in pairs(self.hashTable) do
      table.insert(list, elem)
    end
    return list
  end

  setmetatable(o, metatable)
  return o
end

return Set