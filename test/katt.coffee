{
  _
  should
} = require './_utils'
fixtures = require './katt.fixtures'
katt = undefined # delayed

describe 'katt', () ->
  describe 'run', () ->
    before () ->
      {
        katt
      } = fixtures.run.before()
    after fixtures.run.after

    it 'should run a basic scenario', () ->
      katt.run('/mock/basic.apib').should.eql ''

## Helpers

setup = () ->


