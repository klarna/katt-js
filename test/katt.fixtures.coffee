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
  nock
  mockery
} = require './_utils'

exports.run = {}
exports.run.before = () ->
  # Mock file system
  fs = require 'fs'
  fsMock = _.cloneDeep fs
  fsMock.readFileSync = (filename) ->
    return fsTest1  if filename is '/mock/basic.apib'
    return fsTest2  if filename is '/mock/test-params.apib'
    return fsTest3  if filename is '/mock/api-mismatch.apib'
    return fsTest4  if filename is '/mock/unexpected-disallow.apib'
    return fsTest5  if filename is '/mock/expected-but-undefined.apib'
    return fsTest6  if filename is '/mock/unexpected-and-undefined.apib'
    fs.readFileSync.apply fs, arguments
  mockery.registerMock 'fs', fsMock
  mockery.enable
    useCleanCache: true
    warnOnUnregistered: false
  katt = require '../'


  # Mock response for Step 1
  # (default hostname is 127.0.0.1, default port is 80, default protocol is http)
  nock('http://127.0.0.1')
    .post('/step1')
    .reply 201, '',
      'Location': 'http://127.0.0.1/step2'

  # Mock response for Step 2
  nock('http://127.0.0.1')
    .get('/step2')
    .matchHeader('Accept', 'application/json')
    .reply 200, JSON.stringify({
      required_fields: ['email'],
      cart: '{{_}}',
      extra_object: {
        key: 'test'
      },
      extra_array: ['test']
    }, null, 4), 'Content-Type': 'application/json'

  # Mock response for Step 3
  nock('http://127.0.0.1')
    .post('/step2/step3')
    .reply 200, '{\n    "required_fields": [\n        "password"\n    ],\n    "cart": {"item1": true}\n}',
      'Content-Type': 'application/json'

  # Mock response for Step 4
  nock('http://127.0.0.1')
    .post('/step2/step4')
    .reply 402, '{\n    "error": "payment required"\n}',
      'Content-Type': 'application/json'

  # Mock response for Step 5
  nock('http://127.0.0.1')
    .head('/step5')
    .reply 404, '',
      'Content-Type': 'text/html'

  # Mock response for test-params
  nock('http://example.com')
    .post('/test-params')
    .reply 200, JSON.stringify({
      protocol: 'http:',
      hostname: 'example.com',
      port: 80,
      some_var: 'hi',
      some_var3: 'hihihi',
      'null': null
      boolean: true
      integer: 1
      float: 1.1
      string: 'string'
      binary: 'binary'
    }, null, 4), 'Content-Type': 'application/vnd.katt.test-v1+json'

  # Mock response for api mismatch test
  nock('http://127.0.0.1')
    .post('/api-mismatch')
    .matchHeader('Accept', 'application/json')
    .matchHeader('Content-Type', 'application/json')
    .reply 401, '{\n    "error": "unauthorized"\n}',
      'Content-Type': 'application/json'

  # Mock response for unexpected disallow test
  nock('http://127.0.0.1')
    .get('/unexpected-disallow')
    .reply 401, JSON.stringify({
      extra_object: {
        key: 'test'
      },
      extra_array: ['test']
    }, null, 4), 'Content-Type': 'application/json'

  # Mock response for unexpected disallow test
  nock('http://127.0.0.1')
    .get('/expected-but-undefined')
    .reply 200, JSON.stringify({}, null, 4), 'Content-Type': 'application/json'

  # Mock response for unexpected disallow test
  nock('http://127.0.0.1')
    .get('/unexpected-and-undefined')
    .reply 200, JSON.stringify({}, null, 4), 'Content-Type': 'application/json'

  {
    katt
  }


exports.run.after = () ->
  mockery.disable()
  mockery.deregisterAll()
  nock.cleanAll()


fsTest1 = """--- Test 1 ---

---
Some description
---

# Step 1

The merchant creates a new example object on our server, and we respond with
the location of the created example.

POST /step1
> Accept: application/json
> Content-Type: application/json
{
    "cart": {
        "items": [
            {
                "name": "Horse",
                "quantity": 1,
                "unit_price": 4495000
            },
            {
                "name": "Battery",
                "quantity": 4,
                "unit_price": 1000
            },
            {
                "name": "Staple",
                "quantity": 1,
                "unit_price": 12000
            }
        ]
    }
}
< 201
< Location: {{>example_uri}}


# Step 2

The client (customer) fetches the created resource data.

GET {{<example_uri}}
> Accept: application/json
< 200
< Content-Type: application/json
{
    "required_fields": [
        "email"
    ],
    "cart": "{{_}}"
}


# Step 3

The customer submits an e-mail address in the form.

POST {{<example_uri}}/step3
> Accept: application/json
> Content-Type: application/json
{
    "email": "test-customer@foo.klarna.com"
}
< 200
< Content-Type: application/json
{
    "required_fields": [
        "password"
    ],
    "cart": "{{_}}"
}


# Step 4

The customer submits the form again, this time also with his password.
We inform him that payment is required.

POST {{<example_uri}}/step4
> Accept: application/json
> Content-Type: application/json
{
    "email": "test-customer@foo.klarna.com",
    "password": "correct horse battery staple"
}
< 402
< Content-Type: application/json
{
    "error": "payment required"
}

# Step 5

HEAD /step5
< 404
< Content-Type: text/html
<<<
>>>
"""

fsTest2 = """--- Test 2 ---

POST /test-params
< 200
< Content-Type: application/vnd.katt.test-v{{<version}}+{{<syntax}}
{
    "protocol": "{{<protocol}}",
    "hostname": "{{<hostname}}",
    "port": "{{<port}}",
    "some_var": "{{<some_var}}",
    "some_var3": "hi{{<some_var}}hi",
    "boolean": "{{<test_boolean}}",
    "null": "{{<test_null}}",
    "integer": "{{<test_integer}}",
    "float": "{{<test_float}}",
    "string": "{{<test_string}}",
    "binary": "{{<test_binary}}"
}
"""

fsTest3 = """--- Test 3 ---

POST /api-mismatch
> Accept: application/json
> Content-Type: application/json
{}
< 200
< Content-Type: application/json
{ "ok": true }
"""

fsTest4 = """--- Test 4 ---

GET /unexpected-disallow
< 200
< Content-Type: application/json
{
    "ok": true,
    "extra_object": {
        "{{_}}": "{{unexpected}}"
    },
    "extra_array": ["{{unexpected}}"]
}
"""

fsTest5 = """--- Test 5 ---

GET /expected-but-undefined
< 200
< Content-Type: application/json
{
    "expected": "{{>defined_value}}"
}
"""

fsTest6 = """--- Test 6 ---

GET /unexpected-and-undefined
< 200
< Content-Type: application/json
{
    "expected": "{{unexpected}}"
}
"""
