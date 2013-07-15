utils = require './utils'
katt = require './katt'

exports = module.exports =
  PROTOCOL_HTTP: 'http:'
  PROTOCOL_HTTPS: 'https:'
  DEFAULT_SCENARIO_TIMEOUT: 120000
  DEFAULT_REQUEST_TIMEOUT: 20000
  DEFAULT_PROTOCOL: 'http:'
  DEFAULT_HOSTNAME: '127.0.0.1'
  DEFAULT_PORT_HTTP: 80
  DEFAULT_PORT_HTTPS: 443
  DEFAULT_PARSE_FUNCTION: katt.parse
  DEFAULT_REQUEST_FUNCTION: katt.request
  DEFUALT_VALIDATE_FUNCTION: katt.validate

exports.regexEscape = (text) ->
  text.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\,\\\^\$\|\#\s]/g, '\\$&'

exports.TAGS =
  MATCH_ANY: '{{_}}'
  RECALL_BEGIN: '{{<'
  RECALL_END: '}}'
  STORE_BEGIN: '{{>'
  STORE_END: '}}'
  MARKER_BEGIN: '{'
  MARKER_END: '}'
exports.TAGS_RE = do () ->
  result = {}
  result[tagName] = exports.regexEscape tag  for tagName, tag of exports.TAGS
  result

exports.storeRE = ///
  ^#{exports.TAGS_RE.STORE_BEGIN}
  [^#{exports.TAGS_RE.MARKER_END}]+
  #{exports.TAGS_RE.STORE_END}$
///

exports.matchAnyRE = ///
  #{exports.TAGS_RE.MATCH_ANY}
///
