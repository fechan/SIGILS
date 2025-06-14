local Set = require('sigils.Set')
local PipeGraph = {}

function PipeGraph.new (factory)
  local o = {
    pipes = factory.pipes,
    groups = factory.groups,
    groupConnectedPipes = {}, -- maps Group IDs to a Set of Pipe IDs connected to the Group
  }

  for pipeId, pipe in pairs(factory.pipes) do
    o.groupConnectedPipes[pipe.from] = (o.groupConnectedPipes[pipe.from] or Set.new())
    o.groupConnectedPipes[pipe.from]:add(pipeId)

    o.groupConnectedPipes[pipe.to] = (o.groupConnectedPipes[pipe.to] or Set.new())
    o.groupConnectedPipes[pipe.to]:add(pipeId)
  end

  function o:getDegree (pipeId)
    local pipe = self.pipes[pipeId]
    return (
      (#self.groupConnectedPipes[pipe.from] - 1) +
      (#self.groupConnectedPipes[pipe.to] - 1)
    )
  end

  function o:getNeighbors (pipeId)
    local pipe = self.pipes[pipeId]
    local neighbors = Set.new()

    for _, neighbor in pairs(self.groupConnectedPipes[pipe.from]:toList()) do
        neighbors:add(neighbor)
    end

    for _, neighbor in pairs(self.groupConnectedPipes[pipe.to]:toList()) do
        neighbors:add(neighbor)
    end

    neighbors:remove(pipeId)
    return neighbors:toList()
  end

  return o
end

return PipeGraph