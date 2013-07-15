{
  _
  should
} = require './_utils'
fixtures = require './katt.fixtures'
katt = undefined # delayed
diff = require('json-diff').diff

describe 'katt', () ->
  describe 'run', () ->
    before () ->
      {
        katt
      } = fixtures.run.before()
    after fixtures.run.after

    it 'should run a basic scenario', (done) ->
      scenario = '/mock/basic.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'pass'
        # testResult = {
        #   status: 'pass'
        #   scenario
        #   finalParams:
        #     protocol: 'http:'
        #     hostname: '127.0.0.1'
        #     example_uri: 'http://127.0.0.1/step2'
        # }
        # _.merge testResult, result, _.defaults
        # _.isEqual(result, testResult).should.eql true
        done()

    it 'should run a scenario with params', (done) ->
      scenario = '/mock/test-params.apib'
      params =
        hostname: 'example.com'
        some_var: 'hi'
        version: '1'
      katt.run {scenario, params}, (err, result) ->
        result.status.should.eql 'pass'
        # testResult = {
        #   status: 'pass'
        #   scenario
        #   params
        #   finalParams: _.merge {}, params,
        #     protocol: 'http:'
        # }
        # _.merge testResult, result, _.defaults
        # _.isEqual(result, testResult).should.eql true
        done()

    it.only 'should run and fail on api mismatch', (done) ->
      scenario = '/mock/api-mismatch.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'fail'
        errors = result.transactionResults[0].errors
        errors[0].reason.should.eql 'not_equal'
        errors[0].key.should.eql 'status'
        errors[1].reason.should.eql 'not_equal'
        errors[1].key.should.eql 'body'
        done()
