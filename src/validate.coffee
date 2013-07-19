_ = require 'lodash'
Const = require './const'
utils = require './utils'


# VALIDATE
exports.validate = (key, actual = '', expected = '', params = {}, errors = []) ->
  return errors  if Const.matchAnyRE.test expected
  if utils.isObjectOrArray(actual) or utils.isObjectOrArray(expected)
    errors.push {
      reason: 'not_equal'
      key
      actual
      expected
    }
    return errors
  actual = actual.toString()
  expected = expected.toString()
  # maybe store, maybe recall
  expected = utils.store actual, expected, params
  expected = utils.recall expected, params

  return errors  if actual is expected
  unless actual?
    errors.push {
      reason: 'missing_value'
      key
      actual
      expected
    }
    return errors
  if Const.storeRE.test actual
    errros.push {
      reason: 'empty_value'
      key
      actual
      expected
    }
    return errors
  errors.push {
    reason: 'not_equal'
    key
    actual
    expected
  }
  errors


exports.validateDeep = (key, actual, expected, params, errors) ->
  if utils.isObjectOrArray(actual) and utils.isObjectOrArray(expected)
    keys = _.sortBy _.union _.keys(actual), _.keys(expected)
    for key in keys
      if utils.isObjectOrArray expected[key]
        exports.validateDeep key, actual[key], expected[key], params, errors
      else
        exports.validate key, actual[key], expected[key], params, errors
    errors
  else
    exports.validate key, actual, expected, params, errors


exports.validateStatusCode = (actual, expected, params, errors) ->
  exports.validate 'status', actual, expected, params, errors
  errors


exports.validateUrl = (actual, expected, params = {}, errors = []) ->
  actual = utils.normalizeUrl actual, params
  expected = utils.recall expected, params
  expected = utils.normalizeUrl expected, params

  exports.validate 'url', actual, expected, params, errors
  errors


exports.validateHeaders = (actual, expected, params = {}, errors = []) ->
  actual = utils.normalizeHeaders actual
  expected = utils.recallDeep expected, params
  expected = utils.normalizeHeaders expected

  for header of expected
    exports.validate header, actual[header], expected[header], params, errors
  errors


exports.validateBody = (actual, expected, params = {}, errors = []) ->
  if utils.isObjectOrArray(actual) and utils.isObjectOrArray(expected)
    exports.validateDeep 'body', actual, expected, params, errors
  else
    exports.validate 'body', actual, expected, params, errors
