local PipeSaturation = {}

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

  function o:toString ()
    return self.saturation .. ' ' .. self.degreeColorless
  end

  return o
end

return PipeSaturation