local PipeBatcher = require('sigils.pipeBatcher')

local testFactory = require('tests.mock.factory')

for k,v in pairs(PipeBatcher.batchPipes(testFactory)) do
  for k2,v2 in pairs(v) do
    print(k, v2)
  end
end