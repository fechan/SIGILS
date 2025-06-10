local PipeSaturation = {}

local metatable = {
  __eq = function (lhs, rhs)
    return (
      lhs.saturation == rhs.saturation and
      lhs.degreeColorless == rhs.degreeColorless
    )
  end,

  --- This function is REVERSED because pipe.lua uses a min heap, but we actually
  --- want to pop the pipe with the max saturation
  __lt = function (lhs, rhs)
    if lhs.saturation > rhs.saturation then
      return true
    else
      return lhs.degreeColorless > rhs.degreeColorless
    end
  end
}

function PipeSaturation.new (numNeighbors, pipeId)
  local o = {
    neighborColors = {},
    saturation = 0,

    degreeColorless = numNeighbors,

    pipeId = pipeId
  }

  function o:addNeighborColor (color)
    self.degreeColorless = self.degreeColorless - 1
    if not self.neighborColors[color] then
      self.neighborColors[color] = true
      self.saturation = self.saturation + 1
    end
  end

  function o:hasNeighborOfColor (color)
    return self.neighborColors[color] ~= nil
  end

  setmetatable(o, metatable)

  return o
end

return PipeSaturation