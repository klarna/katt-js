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
