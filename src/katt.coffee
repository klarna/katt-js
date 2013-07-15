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
defaultParams =
  protocol: Const.DEFAULT_PROTOCOL
  hostname: Const.DEFAULT_HOSTNAME
  port: Const.DEFAULT_PORT
  scenarioTimeout: Const.DEFAULT_SCENARIO_TIMEOUT
  requestTimeout: Const.DEFAULT_REQUEST_TIMEOUT
defaultCallbacks = require './callbacks'


#
# API
#

exports.makeRequestUrl = (url, params, callbacks) ->
  return url  if url.indexOf(Const.PROTOCOL_HTTP) is 0
  return url  if url.indexOf(Const.PROTOCOL_HTTPS) is 0
  urlLib.format
    protocol: params.protocol
    hostname: params.hostname
    port: params.port
    pathname: url


exports.makeKattRequest = (request, params, callbacks) ->
  request = utils.recallDeep request, params
  url = utils.recall request.url, params
  request.url = exports.makeRequestUrl url, params, callbacks
  request


exports.makeKattResponse = (response, params, callbacks) ->
  response = utils.recallDeep response, params
  response.body = callbacks.parse {
    headers: response.headers
    body: response.body
    params
    callbacks
  }
  response

exports.runTransaction = ({scenario, transaction, params, callbacks}, next) ->
  {
    description
    request
    response
  } = transaction
  initialParams = _.cloneDeep params
  request = exports.makeKattRequest request, params, callbacks
  expected = exports.makeKattResponse response, params, callbacks
  callbacks.request {request, params, callbacks}, (err, actual) ->
    return next err  if err?
    callbacks.validate {actual, expected, params, callbacks}, (err, errors) ->
      return next err  if err?
      next null, {
        description
        request
        params: initialParams
        errors
      }


exports.runTransactions = ({scenario, transactions, params, callbacks}, next) ->
  params ?= {}
  callbacks ?= {}
  params = _.defaults params, defaultParams
  callbacks = _.defaults callbacks, defaultCallbacks
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
  blueprint = blueprintParser.parse fs.readFileSync scenario, 'utf8'
  return blueprint
  # FIXME
  # NOTE probably should return a normalized copy
  for transaction in blueprint.transactions
    for reqres in [transaction.request, transaction.response]
      reqres.headers = utils.normalizeHeaders reqres.headers
      # reqres.body = utils.maybeJsonBody reqres  if reqres.body?
  blueprint


exports.run = ({scenario, params, callbacks}, next) ->
  blueprint = exports.readScenario scenario

  # TODO implement timeouts, spawn process?
  exports.runScenario {scenario, blueprint, params, callbacks}, (err, result) ->
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
