local PipeGraph = require('sigils.PipeGraph')

local testFactory = require('tests.mock.factory')

local graph = PipeGraph.new(testFactory)

print(#graph:getNeighbors('pipe1'))
print(graph:getDegree('pipe1'))