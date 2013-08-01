http = require 'http'
url = require 'url'
_ = require 'lodash'
utils = require './utils'
{
  validateStatusCode
  validateHeaders
  validateBody
} = require './validate'


exports.recall = ({syntax, text, params, callbacks}) ->
  return text  if not _.isString text or _.isEmpty params
  syntax ?= 'text'
  return text  unless syntax in ['text', 'json']
  for key, value of params
    keyRE = Const.regexEscape key
    keyRE = "#{Const.TAGS_RE.RECALL_BEGIN}#{keyRE}#{Const.TAGS_RE.RECALL_END}"
    keyRE = "\"#{keyRE}\""  if syntax is 'json' and not _.isString value
    keyRE = new RegExp keyRE, 'g'
    text = text.replace keyRE, value
  text


exports.recall_body = ({headers, body, params, callbacks}) ->
  syntax = 'text'
  contentType = headers['content-type']
  syntax = 'json'  if contentType? and utils.isJsonCT contentType
  exports.recall {syntax, body, params, callbacks}


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

  req = http.request options, (res) ->
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
  req.on 'data', () ->
    req.write request.body, 'utf8'  if request.body?
  req.on 'error', next
  req.end()


exports.validate = ({actual, expected, params, callbacks}, next) ->
  errors = []
  validateStatusCode actual.status, expected.status, params, errors
  validateHeaders actual.headers, expected.headers, params, errors
  validateBody actual.body, expected.body, params, errors
  next null, errors
