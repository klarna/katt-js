{
  _
  should
  sandboxedModule
} = require './_utils'
index = sandboxedModule.require '../',
  requires:
    fs:
      readFileSync: (filename) ->
        return fsTest1  if filename is '/mock/basic.apib'
        return fsTest2  if filename is '/mock/test-params.apib'
        return fsTest3  if filename is '/mock/api-mismatch.apib'
        undefined

describe 'katt', () ->
  describe 'run', () ->
    it 'should run a basic scenario', () ->

## Helpers

# Mock response for Step 1
# (default hostname is 127.0.0.1, default port is 80, default protocol is http)
nock('http://127.0.0.1/step1')
  .post('/foo/examples')
  .reply 200, '',
    Location: 'http://127.0.0.1/step2'

# Mock response for Step 2
nock('http://127.0.0.1')
  .get('/step2')
  .matchHeader('Accept', 'application/json')
  .reply 200, '{\n    "required_fields": [\n        "email"\n    ],\n    "cart": "{{_}}"\n}',
    'Content-Type': 'application/json'

# Mock response for Step 3
nock('http://127.0.0.1')
  .post('/step2/step3')
  .reply 200, '{\n    "required_fields": [\n        "password"\n    ],\n    "cart": {"item1": true}\n}',
    'Content-Type': 'application/json'

# Mock response for Step 4
nock('http://127.0.0.1')
  .post('/step2/step4')
  .reply 402, '{\n    "error": "payment_required"\n}',
    'Content-Type': 'application/json'

# Mock response for Step 5
nock('http://127.0.0.1')
  .head('/step5')
  .reply 404, '',
    'Content-Type': 'text/html'

# Mock response for test-params
nock('http://example.com')
  .post('/test-params')
  .matchHeader('Accept', 'application/json')
  .matchHeader('Content-Type', 'application/vnd.katt.test-v1+json')
  .reply 404, 'Not found',
    'Content-Type': 'text/html'

# Mock response for api mismatch test
nock('http://127.0.0.1')
  .head('/api-mismatch')
  .matchHeader('Accept', 'application/json')
  .matchHeader('Content-Type', 'application/json')
  .reply 401, '{\n    "error": "unauthorized"\n}',
    'Content-Type': 'application/json'
    'Content-Type': 'text/html'


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
"""

fsTest2 = """--- Test 2 ---

POST /test-params
> Accept: text/html
> Content-Type: application/vnd.katt.test-v{{<version}}+json
{
    \"ok\": {{<some_var}}
}
< 404
Not found
"""

fsTest3 = """--- Test 3 ---

POST /api-mismatch
> Accept: application/json
> Content-Type: application/json
{}
< 200
{ \"ok\": true }
"""
