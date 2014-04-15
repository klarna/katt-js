###
   Copyright 2013 Klarna AB

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
###

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

    it 'should run a basic scenario', (done) ->
      scenario = '/mock/basic.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'pass'
        done()

    it 'should run a scenario with params', (done) ->
      scenario = '/mock/test-params.apib'
      params =
        hostname: 'example.com'
        some_var: 'hi'
        version: '1'
        syntax: 'json'
        test_null: null
        test_boolean: true
        test_integer: 1
        test_float: 1.1
        test_string: 'string'
        test_binary: 'binary'
      katt.run {scenario, params}, (err, result) ->
        result.status.should.eql 'pass'
        done()

    it 'should run and fail on api mismatch', (done) ->
      scenario = '/mock/api-mismatch.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'fail'
        errors = result.transactionResults[0].errors
        errors[0].key.should.eql '/status'
        errors[0].reason.should.eql 'not_equal'
        errors[1].key.should.eql '/body/ok'
        errors[1].reason.should.eql 'not_equal'
        done()

    it 'should run and fail on unexpected disallow'

    it 'should run and fail on expected-but-undefined', (done) ->
      scenario = '/mock/expected-but-undefined.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'fail'
        errors = result.transactionResults[0].errors
        errors[0].key.should.eql '/body/expected'
        errors[0].reason.should.eql 'not_equal'
        done()

    it 'should run a scenario with unexpected-and-undefined', (done) ->
      scenario = '/mock/unexpected-and-undefined.apib'
      katt.run {scenario}, (err, result) ->
        result.status.should.eql 'pass'
        done()
