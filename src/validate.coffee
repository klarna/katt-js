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

_ = require 'lodash'
Const = require './const'
utils = require './utils'


# VALIDATE
exports.validate = ({key, actual, expected, params, callbacks, errors}) ->
  errors ?= []
  return errors  if Const.matchAnyRE.test expected
  if utils.isObjectOrArray(actual) or utils.isObjectOrArray(expected)
    errors.push {
      reason: 'not_equal'
      key
      actual
      expected
    }
    return errors
  expected = exports.store {actual, expected, params, callbacks}
  # expected = callbacks.recall {syntax: 'text', expected, params, callbacks}
  if actual isnt undefined
    return errors  if actual is expected
    reason = 'not_equal'
    reason = 'unexpected'  if Const.unexpectedRE.test expected
  else
    return errors  if Const.unexpectedRE.test expected
    reason = 'not_equal'
  errors.push {
    reason
    key
    actual
    expected
  }
  errors


exports.validateDeep = ({key, actual, expected, params, callbacks, errors}) ->
  errors ?= []
  if utils.isObjectOrArray(actual) and utils.isObjectOrArray(expected)
    unexpectedValue = expected[Const.TAGS.MATCH_ANY] or Const.TAGS.MATCH_ANY
    delete expected[Const.TAGS.MATCH_ANY]
    keys = _.sortBy _.union _.keys(actual), _.keys(expected)
    unexpectedKeys = _.sortBy _.difference _.keys(actual), _.keys(expected)
    for subkey in keys
      newKey = "#{key}/#{subkey}"
      expectedValue = expected[subkey]
      expectedValue = unexpectedValue  if subkey in unexpectedKeys
      if utils.isObjectOrArray expected[subkey]
        exports.validateDeep {
          key: newKey
          actual: actual[subkey]
          expected: expectedValue
          params
          callbacks
          errors
        }
      else
        exports.validate {
          key: newKey
          actual: actual[subkey]
          expected: expectedValue
          params
          callbacks
          errors
        }
    errors
  else
    exports.validate {key, actual, expected, params}, errors
  errors


exports.validateStatusCode = ({actual, expected, params, callbacks, errors}) ->
  errors ?= []
  exports.validate {
    key: '/status'
    actual
    expected
    params
    callbacks
    errors
  }
  errors


exports.validateMethod = ({actual, expected, params, callbacks, errors}) ->
  errors ?= []
  actual = actual.toUpperCase()
  expected = expected.toUpperCase()
  exports.validate {
    key: '/method'
    actual
    expected
    params
    callbacks
    errors
  }
  errors


exports.validateUrl = ({actual, expected, params, callbacks, errors}) ->
  errors ?= []
  actual = utils.normalizeUrl actual, params
  expected = utils.normalizeUrl expected, params
  exports.validate {
    key: '/url'
    actual
    expected
    params
    callbacks
    errors
  }
  errors


exports.validateHeaders = ({actual, expected, params, callbacks, errors}) ->
  errors ?= []
  actual = utils.normalizeHeaders actual
  expected = utils.normalizeHeaders expected
  for header of expected
    exports.validate {
      key: "/headers/#{header}"
      actual: actual[header]
      expected: expected[header]
      params
      callbacks
      errors
    }
  errors


exports.validateBody = ({actual, expected, params, callbacks, errors}) ->
  errors ?= []
  validate = exports.validate
  if utils.isObjectOrArray(actual) and utils.isObjectOrArray(expected)
    validate = exports.validateDeep
  validate {
    key: '/body'
    actual
    expected
    params
    callbacks
    errors
  }
  errors


exports.store = ({actual, expected, params}) ->
  return expected  unless _.isString expected
  return expected  if Const.matchAnyRE.test expected
  return expected  unless Const.storeRE.test expected
  expected = expected.replace Const.TAGS.STORE_BEGIN, ''
  expected = expected.replace Const.TAGS.STORE_END, ''
  params[expected] = actual
  actual
