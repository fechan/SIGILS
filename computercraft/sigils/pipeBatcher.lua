local PipeGraph = require('sigils.PipeGraph')
local PipeSaturation = require('sigils.PipeSaturation')
local FibonacciHeap = require('sigils.FibonacciHeap')

--[[
  Treats pipes as vertices in a graph, and colors them with DSatur
  https://en.wikipedia.org/wiki/DSatur
  Each color represents a batch of pipes to run in parallel
]]
local function batchPipes (factory)
  local connectedPipes = PipeGraph.new(factory)

  local heap = FibonacciHeap.new() -- build a heap of pipe IDs needing processing
  local heapNodes = {} -- map Pipe IDs to their node in the heap
  for pipeId, _ in pairs(factory.pipes) do
    local degree = connectedPipes:getDegree(pipeId)
    local pipeSatData = PipeSaturation.new(degree, pipeId)
    local node = heap:insert(pipeSatData:toString(), pipeSatData)
    heapNodes[pipeId] = node
  end

  -- start running DSatur
  local pipeColors = {} -- Maps color IDs to sets of pipe IDs of the same color

  while not heap:isEmpty() do
    local pipeSatData = heap:pop().object -- get the most saturated pipe

    -- find the color with the lowest number not used by any of its neighbors
    local colorNbr = 0
    while pipeSatData:hasNeighborOfColor(colorNbr) do
      colorNbr = colorNbr + 1
    end

    -- set the pipe to that color
    pipeColors[colorNbr] = (pipeColors[colorNbr] or {})
    table.insert(pipeColors[colorNbr], pipeSatData.pipeId)

    -- tell the pipe's neighbors to change their saturation/degree, and update the heap
    for _, neighborPipeId in pairs(connectedPipes:getNeighbors(pipeSatData.pipeId)) do
      local node = heapNodes[neighborPipeId]
      node.object:addNeighborColor(colorNbr)
      heap:decreaseKey(node, node.object:toString())
    end
  end

  return pipeColors
end

return {
  batchPipes = batchPipes,
}