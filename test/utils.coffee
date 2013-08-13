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

{
  _
  should
} = require './_utils'
{
  utils
} = require '../'


describe 'utils', () ->
  describe 'isJsonCT', () ->
    it 'should detect regular JSON media-types', () ->
      CTs = [
        'application/json'
        'application/json;charset=utf-8'
        'application/json; charset=utf-8'
      ]
      for CT in CTs
        utils.isJsonCT(CT).should.eql true

    it 'should detect suffixed JSON media-types', () ->
      CTs = [
        'application/example+json'
        'application/example+json;charset=utf-8'
        'application/vnd.example.com-v1+json'
      ]
      for CT in CTs
        utils.isJsonCT(CT).should.eql true


  describe 'maybeJsonBody', () ->
    makeReqRes = (CT, body) ->
      {
        headers:
          'content-type': CT
        body
      }
    it 'should return JSON when detecting JSON message bodies', () ->
      body = '{"test":true}'
      reqRes = makeReqRes 'application/json', body
      utils.maybeJsonBody(reqRes).should.eql {test:true}

    it 'should return the body as it is, if it is not JSON', () ->
      body = ''
      reqRes = makeReqRes 'text/plain', body
      utils.maybeJsonBody(reqRes).should.eql body

      reqRes = makeReqRes 'application/json', body
      utils.maybeJsonBody(reqRes).should.eql body


  describe 'normalizeHeaders', () ->
    it 'should lowercase headers', () ->
      headers =
        'ETag': ''
        'Content-Location': ''
        'Content-MD5': ''
      utils.normalizeHeaders(headers).should.eql {
        'etag': ''
        'content-location': ''
        'content-md5': ''
      }

    it 'should remove charset parameter from Content-Type', () ->
      headers =
        'Content-Type': 'application/json; charset=utf-8'
      utils.normalizeHeaders(headers).should.eql {
        'content-type': 'application/json'
      }


  describe 'normalizeUrl', () ->
    it 'should remove non-path components on host=hostname matches', () ->
      vars = {
        host: 'example.com'
        hostname: 'example.com'
        port: undefined
      }
      Url = "http://#{vars.host}/test"
      utils.normalizeUrl(Url, vars).should.equal '/test'

    it 'should remove non-path components on host=hostname:port matches', () ->
      vars = {
        host: 'example.com:80'
        hostname: 'example.com'
        port: '80'
      }
      Url = "http://#{vars.host}/test"
      utils.normalizeUrl(Url, vars).should.equal '/test'

    it 'should leave non-path components on host mismatches', () ->
      vars = {
        host: 'example.com:80'
        hostname: 'example.com'
        port: '80'
      }
      Url = "http://example.com:8080/test"
      utils.normalizeUrl(Url, vars).should.equal Url
      Url = "http://example2.com/test"
      utils.normalizeUrl(Url, vars).should.equal Url


  describe 'parseHost', () ->
    it 'should accept hostname', () ->
      host = 'example.com'
      utils.parseHost(host).should.eql {
        host
        hostname: 'example.com'
        port: undefined
      }

    it 'should accept hostname:port', () ->
      host = 'example.com:80'
      utils.parseHost(host).should.eql {
        host
        hostname: 'example.com'
        port: '80'
      }
