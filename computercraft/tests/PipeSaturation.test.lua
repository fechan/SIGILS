local PipeSaturation = require('sigils.PipeSaturation')
local PipeGraph = require('sigils.PipeGraph')

local testFactory = require('tests.mock.factory')

local graph = PipeGraph.new(testFactory)

pipeSat = PipeSaturation.new(#graph:getNeighbors('pipe1'), 'pipe1')

print(pipeSat.degreeColorless)
pipeSat:addNeighborColor(1)
print(pipeSat.degreeColorless)
print(pipeSat.saturation)