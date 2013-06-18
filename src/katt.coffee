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
_ = require 'lodash'
blueprintParser = require 'katt-blueprint-parser'
utils = exports.utils = require './utils'
Const = exports.Const = require './const'

TAGS =
  MATCH_ANY: '{{_}}'
  RECALL_BEGIN: '{{<'
  RECALL_END: '}}'
  STORE_BEGIN: '{{>'
  STORE_END: '}}'
  MARKER_BEGIN: '{'
  MARKER_END: '}'
TAGS_RE = do () ->
  result = {}
  result[tagName] = utils.regexEscape tag  for tagName, tag of TAGS
  result

###
recallRE = ///
  ^#{TAGS_RE.RECALL_BEGIN}
  [^#{TAGS_RE.MARKER_END}]+
  #{TAGS_RE.RECALL_END}$
///
###

storeRE = ///
  ^#{TAGS_RE.STORE_BEGIN}
  [^#{TAGS_RE.MARKER_END}]+
  #{TAGS_RE.STORE_END}$
///

###
subRE = ///
  ^#{TAGS_RE.SUBE_BEGIN}
  [^#{TAGS_RE.MARKER_END}]+
  #{TAGS_RE.SUBE_END}$
///
###

matchAnyRE = ///
  #{TAGS_RE.MATCH_ANY}
///

#
# API
#

# VALIDATE
exports.validate = (key, actualValue, expectedValue, vars = {}, result = []) ->
  return result  if matchAnyRE.test expectedValue
  # maybe store, maybe recall
  exports.store actualValue, expectedValue, vars
  expectedValue = exports.recall expectedValue, vars

  return result  if actualValue is expectedValue
  unless actualValue?
    result.push.apply result, [['missing_value', key, actualValue, expectedValue]]
    return result
  if storeRE.test actualValue
    result.push.apply result, [['empty_value', key, actualValue, expectedValue]]
    return result
  result.push.apply result, [['not_equal', key, actualValue, expectedValue]]
  result


exports.validateDeep = (key, actualValue, expectedValue, vars, result) ->
  if utils.isPlainObjectOrArray(actualValue) and utils.isPlainObjectOrArray(expectedValue)
    keys = _.sortBy _.union _.keys(actualValue), _.keys(expectedValue)
    for key in keys
      if utils.isPlainObjectOrArray expectedValue[key]
        exports.validateDeep key, actualValue[key], expectedValue[key], vars, result
      else
        exports.validate key, actualValue[key], expectedValue[key], vars, result
    result
  else
    exports.validate key, actualValue, expectedValue, vars, result


exports.validateUrl = (actualUrl, expectedUrl, vars = {}) ->
  result = []
  actualUrl = utils.normalizeUrl actualUrl, vars
  expectedUrl = exports.recall expectedUrl, vars
  expectedUrl = utils.normalizeUrl expectedUrl, vars

  exports.validate 'url', actualUrl, expectedUrl, vars, result
  result


exports.validateHeaders = (actualHeaders, expectedHeaders, vars = {}) ->
  result = []
  actualHeaders = utils.normalizeHeaders actualHeaders
  expectedHeaders = exports.recallDeep expectedHeaders, vars
  expectedHeaders = utils.normalizeHeaders expectedHeaders

  for header of expectedHeaders
    exports.validate header, actualHeaders[header], expectedHeaders[header], vars, result
  result


exports.validateBody = (actualBody, expectedBody, vars = {}, result = []) ->
  result = []
  if utils.isPlainObjectOrArray(actualBody) and utils.isPlainObjectOrArray(expectedBody)
    exports.validateDeep 'body', actualBody, expectedBody, vars, result
  else
    # actualBody = JSON.stringify actualBody, null, 2  unless _.isString actualBody
    # expectedBody = JSON.stringify expectedBody, null, 2  unless _.isString expectedBody
    exports.validate 'body', actualBody, expectedBody, vars, result


exports.validateResponse = (actualResponse, expectedResponse, vars = {}, result = []) ->
  # TODO check status
  # TODO check headers
  # TODO check body


# STORE
exports.store = (actualValue, expectedValue, vars = {}) ->
  return vars  unless _.isString expectedValue
  return vars  if matchAnyRE.test expectedValue
  return vars  unless storeRE.test expectedValue
  expectedValue = expectedValue.replace TAGS.STORE_BEGIN, ''
  expectedValue = expectedValue.replace TAGS.STORE_END, ''
  vars[expectedValue] = actualValue


exports.storeDeep = (actualValue, expectedValue, vars = {}) ->
  if utils.isPlainObjectOrArray(actualValue) and utils.isPlainObjectOrArray(expectedValue)
    keys = _.sortBy _.union _.keys(actualValue), _.keys(expectedValue)
    for key in keys
      if utils.isPlainObjectOrArray expectedValue[key]
        exports.storeDeep actualValue[key], expectedValue[key], vars
      else
        exports.store actualValue[key], expectedValue[key], vars
    vars
  else
    exports.store actualValue, expectedValue, vars


# RECALL
exports.recall = (expectedValue, vars = {}) ->
  return expectedValue  unless _.isString expectedValue
  for key, value of vars
    keyRE = utils.regexEscape key
    keyRE = new RegExp "#{TAGS_RE.RECALL_BEGIN}#{keyRE}#{TAGS_RE.RECALL_END}", 'g'
    expectedValue = expectedValue.replace keyRE, value
  expectedValue


exports.recallDeep = (expectedValue, vars = {}) ->
  if utils.isPlainObjectOrArray expectedValue
    keys = _.keys expectedValue
    expectedValue = _.clone expectedValue
    for key in keys
      if utils.isPlainObjectOrArray expectedValue[key]
        expectedValue[key] = exports.recallDeep expectedValue[key], vars
      else
        expectedValue[key] = exports.recall expectedValue[key], vars
    expectedValue
  else
    exports.recall expectedValue, vars


# RUN
exports.run = (scenario, params = {}, callbacks = {}) ->
  blueprint = exports.readScenario scenario
  protocol = params.protocol or Const.DEFAULT_PROTOCOL
  params = _.merge {
    protocol: Const.DEFAULT_PROTOCOL
    hostname: Const.DEFAULT_HOSTNAME
    port: Const.DEFAULT_PORT
    scenarioTimeout: Const.DEFAULT_SCENARIO_TIMEOUT
    requestTimeout: Const.DEFAULT_REQUEST_TIMEOUT
  }, params

  # TODO implement timeouts, spawn process?
  exports.runScenario scenario, blueprint.operations, params, callbacks


exports.readScenario = (scenario) ->
  blueprint = blueprintParser.parse fs.readFileSync scenario, 'utf8'
  # NOTE probably should return a normalized copy
  for operation in blueprint.operations
    for reqres in [operation.request, operation.response]
      reqres.headers = utils.normalizeHeaders reqres.headers
      reqres.body = utils.maybeJsonBody reqres  if reqres.body?
  blueprint


exports.runScenario = (scenario, blueprintOrOperations, params = {}, callbacks = {}) ->
  if blueprintOrOperations.operations?
    exports.runScenario scenario, blueprintOrOperations.operations, params, callbacks
  operations = blueprintOrOperations
  for operation in operations
    request = makeRequest operation.request, params, callbacks
    expectedResponse = makeResponse operation.response, callbacks
    actualResponse = getResponse request
    result = exports.validateResponse actualResponse, expectedResponse
    return result  if result.length isnt 0
  # TODO
