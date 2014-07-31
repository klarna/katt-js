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

http = require 'http'
https = require 'https'
url = require 'url'
_ = require 'lodash'
utils = require './utils'
Const = require './const'
{
  validateStatusCode
  validateHeaders
  validateBody
} = require './validate'


exports.recall = ({scope, input, params, callbacks}) ->
  return input  if not input? or _.isEmpty params
  scope ?= 'text'
  switch scope
    when 'url'
      return exports.recall {scope: 'text', input, params, callbacks}
    when 'headers'
      _.each input, (value, key) ->
        input[key] = exports.recall {scope: 'text', input: value, params, callbacks}
      return input
    when 'body'
      scope = 'text'
      {headers, body} = input
      contentType = headers['content-type']
      scope = 'json'  if contentType? and utils.isJsonCT contentType
      return {headers, body: exports.recall {scope, input: body, params, callbacks}}
    when 'text', 'json'
      for key, value of params
        keyRE = Const.regexEscape key
        keyRE = "#{Const.TAGS_RE.RECALL_BEGIN}#{keyRE}#{Const.TAGS_RE.RECALL_END}"
        keyRE = "\"?#{keyRE}\"?"  if scope is 'json' and not _.isString value
        keyRE = new RegExp keyRE, 'g'
        input = input.replace keyRE, value
      return input


exports.parse = ({headers, body, params, callbacks}) ->
  contentType = headers['content-type']
  return JSON.parse body  if contentType? and utils.isJsonCT contentType
  body


exports.request = ({request, params, callbacks}, finalNext) ->
  next = (err, res) ->
    return finalNext err  if err
    headers = utils.normalizeHeaders res.headers
    res.body = callbacks.parse {headers, body: res.body, params, callbacks}
    finalNext null, {
      status: res.statusCode
      headers: res.headers
      body: res.body
    }

  options = url.parse request.url
  options.method = request.method
  options.headers = request.headers
  switch options.protocol
    when 'http:'
      protocol = http
    when 'https:'
      protocol = https
    else
      throw new Error "Unknown protocol #{options.protocol}"

  req = protocol.request options, (res) ->
    res.setEncoding 'utf8'
    res.body = ''
    res.on 'data', (chunk) ->
      res.body += chunk
    res.on 'end', () ->
      next null,
        statusCode: res.statusCode
        headers: res.headers
        body: res.body or null
    res.on 'error', next
  req.on 'socket', (socket) ->
    socket.setTimeout params.requestTimeout, req.abort
  req.on 'error', next
  req.write request.body, 'utf8'  if request.body?
  req.end()


exports.validate = ({actual, expected, params, callbacks}, next) ->
  errors = []
  validateStatusCode {actual: actual.status, expected: expected.status, params, errors}
  validateHeaders {actual: actual.headers, expected: expected.headers, params, errors}
  validateBody {actual: actual.body, expected: expected.body, params, errors}
  next null, errors
