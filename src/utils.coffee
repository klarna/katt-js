url = require 'url'
_ = require 'lodash'
Const = require './const'


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
