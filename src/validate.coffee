_ = require 'lodash'
Const = require './const'
utils = require './utils'


# VALIDATE
exports.validate = (key, actualValue = '', expectedValue = '', vars = {}, errors = []) ->
  actualValue = actualValue.toString()
  expectedValue = expectedValue.toString()
  return errors  if Const.matchAnyRE.test expectedValue
  # maybe store, maybe recall
  expectedValue = utils.store actualValue, expectedValue, vars
  expectedValue = utils.recall expectedValue, vars

  return errors  if actualValue is expectedValue
  unless actualValue?
    errors.push {
      reason: 'missing_value'
      key
      actualValue
      expectedValue
    }
    return errors
  if Const.storeRE.test actualValue
    errros.push {
      reason: 'empty_value'
      key
      actualValue
      expectedValue
    }
    return errors
  errors.push {
    reason: 'not_equal'
    key
    actualValue
    expectedValue
  }
  errors


exports.validateDeep = (key, actualValue, expectedValue, vars, errors) ->
  if utils.isObjectOrArray(actualValue) and utils.isObjectOrArray(expectedValue)
    keys = _.sortBy _.union _.keys(actualValue), _.keys(expectedValue)
    for key in keys
      if utils.isObjectOrArray expectedValue[key]
        exports.validateDeep key, actualValue[key], expectedValue[key], vars, errors
      else
        exports.validate key, actualValue[key], expectedValue[key], vars, errors
    errors
  else
    exports.validate key, actualValue, expectedValue, vars, errors


exports.validateStatusCode = (actual, expected, vars, errors) ->
  exports.validate 'status', actual, expected, vars, errors
  errors


exports.validateUrl = (actualUrl, expectedUrl, vars = {}, errors = []) ->
  actualUrl = utils.normalizeUrl actualUrl, vars
  expectedUrl = utils.recall expectedUrl, vars
  expectedUrl = utils.normalizeUrl expectedUrl, vars

  exports.validate 'url', actualUrl, expectedUrl, vars, errors
  errors


exports.validateHeaders = (actualHeaders, expectedHeaders, vars = {}, errors = []) ->
  actualHeaders = utils.normalizeHeaders actualHeaders
  expectedHeaders = utils.recallDeep expectedHeaders, vars
  expectedHeaders = utils.normalizeHeaders expectedHeaders

  for header of expectedHeaders
    exports.validate header, actualHeaders[header], expectedHeaders[header], vars, errors
  errors


exports.validateBody = (actualBody, expectedBody, vars = {}, errors = []) ->
  if utils.isObjectOrArray(actualBody) and utils.isObjectOrArray(expectedBody)
    exports.validateDeep 'body', actualBody, expectedBody, vars, errors
  else
    # actualBody = JSON.stringify actualBody, null, 2  unless _.isString actualBody
    # expectedBody = JSON.stringify expectedBody, null, 2  unless _.isString expectedBody
    exports.validate 'body', actualBody, expectedBody, vars, errors
