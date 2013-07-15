http = require 'http'
url = require 'url'
_ = require 'lodash'
utils = require './utils'
{
  validateStatusCode
  validateHeaders
  validateBody
} = require './validate'


exports.parse = ({headers, body, params, callbacks}) ->
  contentType = _.find headers, (value, header) -> header.toLowerCase() is 'content-type' # FIXME normalize headers
  return JSON.parse body  if contentType? and utils.isJsonCT contentType
  body


exports.request = ({request, params, callbacks}, next) ->
  exports.httpRequest {request, params, callbacks}, (err, res) ->
    return next err  if err
    # FIXME normalize headers
    res.body = callbacks.parse {headers: res.headers, body: res.body, params, callbacks}
    next null, {
      status: res.statusCode
      headers: res.headers
      body: res.body
    }


exports.httpRequest = ({request, params, callbacks}, next) ->
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
    res.on 'error', (e) ->
      next e
  req.on 'data', () ->
    req.write request.body, 'utf8'  if request.body?
  req.on 'error', (e) ->
    next e
  req.end()


exports.validate = ({actual, expected, params, callbacks}, next) ->
  errors = []
  validateStatusCode actual.status, expected.status, params, errors
  validateHeaders actual.headers, expected.headers, params, errors
  validateBody actual.body, expected.body, params, errors
  next null, errors
