local PipeGraph = {}

function PipeGraph.new (factory)
  local o = {
    pipes = factory.pipes,
    groups = factory.groups,
    groupConnectedPipes = {}, -- maps Group IDs to a list of Pipe IDs connected to the Group
  }

  for pipeId, pipe in pairs(factory.pipes) do
    o.groupConnectedPipes[pipe.from] = (o.groupConnectedPipes[pipe.from] or {})
    table.insert(connectedPipes[pipe.from], pipeId)

    o.groupConnectedPipes[pipe.to] = (o.groupConnectedPipes[pipe.from] or {})
    table.insert(connectedPipes[pipe.to], pipeId)
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
    local neighbors = {}

    for _, neighbor in pairs(self.groupConnectedPipes[pipes.from]) do
      if neighbor ~= pipeId then
        table.insert(neighbors, neighbor)
      end
    end

    for _, neighbor in pairs(self.groupConnectedPipes[pipes.to]) do
      if neighbor ~= pipeId then
        table.insert(neighbors, neighbor)
      end
    end

    return neighbors
  end

  return o
end

return PipeGraph