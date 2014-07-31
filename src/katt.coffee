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

fs = require 'fs'
urlLib = require 'url'
_ = require 'lodash'
blueprintParser = require 'katt-blueprint-parser'
utils = exports.utils = require './utils'
Const = exports.Const = require './const'
defaultCallbacks = exports.callbacks = require './callbacks'
exports.validate = require './validate'
defaultParams =
  protocol: Const.DEFAULT_PROTOCOL
  hostname: Const.DEFAULT_HOSTNAME
  port: Const.DEFAULT_PORT_HTTP
  scenarioTimeout: Const.DEFAULT_SCENARIO_TIMEOUT
  requestTimeout: Const.DEFAULT_REQUEST_TIMEOUT


#
# API
#

exports.makeRequestUrl = ({url, params, callbacks}) ->
  return url  if url.indexOf(Const.PROTOCOL_HTTP) is 0
  return url  if url.indexOf(Const.PROTOCOL_HTTPS) is 0
  {protocol, hostname, port} = params
  portIsNotNeeded = protocol is Const.PROTOCOL_HTTP and port is Const.DEFAULT_PORT_HTTP
  portIsNotNeeded = portIsNotNeeded or (protocol is Const.PROTOCOL_HTTPS and port is Const.DEFAULT_PORT_HTTPS)
  port = undefined  if portIsNotNeeded
  urlObj = _.merge urlLib.parse(url), {protocol, hostname, port}
  urlLib.format urlObj


exports.makeKattRequest = ({request, params, callbacks}) ->
  url = request.url
  url = callbacks.recall {scope: 'url', input: url, params, callbacks}
  url = exports.makeRequestUrl {url, params, callbacks}
  headers = request.headers
  headers = callbacks.recall {scope: 'headers', input: headers, params, callbacks}
  body = request.body
  {body} = callbacks.recall {scope: 'body', input: {headers, body}, params, callbacks}
  request = _.assign request, {
    url
    headers
    body
  }
  request


exports.makeKattResponse = ({response, params, callbacks}) ->
  headers = response.headers
  headers = utils.normalizeHeaders headers
  headers = callbacks.recall {scope: 'headers', input: headers, params, callbacks}
  body = response.body
  {body} = callbacks.recall {scope: 'body', input: {headers, body}, params, callbacks}
  body = callbacks.parse {
    headers
    body
    params
    callbacks
  }
  response = _.assign response, {
    headers
    body
  }
  response


exports.runTransaction = ({scenario, transaction, params, callbacks}, next) ->
  {
    description
    request
    response
  } = transaction
  initialParams = _.cloneDeep params
  request = exports.makeKattRequest {request, params, callbacks}
  expected = exports.makeKattResponse {response, params, callbacks}
  callbacks.request {request, params, callbacks}, (err, actual) ->
    return next err  if err?
    callbacks.validate {actual, expected, params, callbacks}, (err, errors) ->
      return next err  if err?
      next null, {
        description
        request
        response: actual
        params: initialParams
        errors
      }


exports.runTransactions = ({scenario, transactions, params, callbacks}, next) ->
  initialParams = _.cloneDeep params

  transactionIndex = 0
  transaction = transactions[transactionIndex]
  transactionResults = []
  loopNext = (err, iterationResult) ->
    return next err  if err?
    transactionResults.push iterationResult
    transactionIndex += 1
    transaction = transactions[transactionIndex]
    if transaction?
      exports.runTransaction {scenario, transaction, params, callbacks}, loopNext
    else
      next null, {
        finalParams: params
        transactionResults
      }
  exports.runTransaction {scenario, transaction, params, callbacks}, loopNext


exports.runScenario = ({scenario, blueprint, params, callbacks}, next) ->
  transactions = blueprint.transactions
  exports.runTransactions {scenario, transactions, params, callbacks}, next


exports.readScenario = (scenario) ->
  blueprintParser.parse fs.readFileSync scenario, 'utf8'


exports.run = ({scenario, params, callbacks}, next) ->
  params ?= {}
  callbacks ?= {}
  params.port ?= Const.DEFAULT_PORT_HTTPS  if params.protocol is Const.PROTOCOL_HTTPS
  params = _.defaults params, defaultParams
  callbacks = _.defaults callbacks, defaultCallbacks
  blueprint = exports.readScenario scenario

  scenarioTimedOut = false
  exports.runScenario {scenario, blueprint, params, callbacks}, (err, result) ->
    return  if scenarioTimedOut
    clearTimeout scenarioTimer
    return next err  if err?
    {
      finalParams
      transactionResults
    } = result
    failures = _.filter transactionResults, (transactionResult) ->
      transactionResult.errors.length
    status = 'pass'
    status = 'fail'  unless failures.length is 0
    next null, {
      status
      scenario
      params
      finalParams
      transactionResults
    }
  scenarioTimingOut = () ->
    scenarioTimedOut = true
    next {
      status: error
      reason: 'timeout'
      details: params.scenarioTimeout
    }
  scenarioTimer = setTimeout scenarioTimingOut, params.scenarioTimeout
