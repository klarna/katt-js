url = require 'url'
_ = require 'lodash'
Const = require './const'


# STORE
exports.store = (actualValue, expectedValue, params = {}) ->
  return params  unless _.isString expectedValue
  return params  if Const.matchAnyRE.test expectedValue
  return params  unless Const.storeRE.test expectedValue
  expectedValue = expectedValue.replace Const.TAGS.STORE_BEGIN, ''
  expectedValue = expectedValue.replace Const.TAGS.STORE_END, ''
  params[expectedValue] = actualValue


exports.storeDeep = (actualValue, expectedValue, params = {}) ->
  if exports.isObjectOrArray(actualValue) and exports.isObjectOrArray(expectedValue)
    keys = _.sortBy _.union _.keys(actualValue), _.keys(expectedValue)
    for key in keys
      if exports.isObjectOrArray expectedValue[key]
        exports.storeDeep actualValue[key], expectedValue[key], params
      else
        exports.store actualValue[key], expectedValue[key], params
    params
  else
    exports.store actualValue, expectedValue, params


# RECALL
exports.recall = (expectedValue, params = {}) ->
  return expectedValue  unless _.isString expectedValue
  for key, value of params
    keyRE = Const.regexEscape key
    keyRE = new RegExp "#{Const.TAGS_RE.RECALL_BEGIN}#{keyRE}#{Const.TAGS_RE.RECALL_END}", 'g'
    expectedValue = expectedValue.replace keyRE, value
  expectedValue


exports.recallDeep = (expectedValue, params = {}) ->
  if exports.isObjectOrArray expectedValue
    keys = _.keys expectedValue
    expectedValue = _.clone expectedValue
    for key in keys
      if exports.isObjectOrArray expectedValue[key]
        expectedValue[key] = exports.recallDeep expectedValue[key], params
      else
        expectedValue[key] = exports.recall expectedValue[key], params
    expectedValue
  else
    exports.recall expectedValue, params


# MISC
exports.defaultPort =
  'http:': '80'
  'https:': '443'

exports.isObjectOrArray = (obj) ->
  _.isObject(obj) or _.isArray(obj)

exports.isJsonCT = (contentType) ->
  /\bjson\b/.test contentType

exports.maybeJsonBody = (reqres) ->
  contentType = reqres.headers?['content-type'] or reqres.get?('content-type') or ''
  if exports.isJsonCT contentType
    try
      return JSON.parse reqres.body
  reqres.body


exports.normalizeHeaders = (headers) ->
  result = {}
  for name, value of headers
    # Lowercase names
    # since headers are case-insensitive
    name = name.trim().toLowerCase()
    # Ignore charset param in Content-Type headers
    # and allow real browser requests to validate
    # see https://bugzilla.mozilla.org/show_bug.cgi?id=416178
    if name is 'content-type'
      value = value.replace /;\s*charset=[^\s;]+\s*/, ''
    result[name] = value
  result


exports.normalizeUrl = (Url, params = {}) ->
  result = url.parse Url
  result.port ?= exports.defaultPort[result.protocol]
  sameHostname = (result.hostname is params.hostname)
  samePort = not params.port or (result.port is params.port.toString())
  if sameHostname and samePort
    delete result.protocol
    delete result.slashes
    delete result.hostname
    delete result.host
    delete result.port
    result = url.format result
    result
  else
    Url


exports.parseHost = (host) ->
  [hostname, port] = host.split ':'
  {
    host
    hostname
    port
  }
