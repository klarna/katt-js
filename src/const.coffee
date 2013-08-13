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

utils = require './utils'

exports = module.exports =
  PROTOCOL_HTTP: 'http:'
  PROTOCOL_HTTPS: 'https:'
  DEFAULT_SCENARIO_TIMEOUT: 120000
  DEFAULT_REQUEST_TIMEOUT: 20000
  DEFAULT_PROTOCOL: 'http:'
  DEFAULT_HOSTNAME: '127.0.0.1'
  DEFAULT_PORT_HTTP: 80
  DEFAULT_PORT_HTTPS: 443

exports.regexEscape = (text) ->
  text.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\,\\\^\$\|\#\s]/g, '\\$&'

exports.TAGS =
  MATCH_ANY: '{{_}}'
  UNEXPECTED: '{{unexpected}}'
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
  ^#{exports.TAGS_RE.MATCH_ANY}$
///

exports.unexpectedRE = ///
  ^#{exports.TAGS_RE.UNEXPECTED}$
///
