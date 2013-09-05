# KATT(js)

KATT (Klarna API Testing Tool) is an HTTP-based testing tool for Node.


## Quick start

Use for shooting HTTP requests in a sequential order and verifying the response.
Any relevant difference between expected and actual responses will cause a
failure.

The validator makes use of a few tags with special meaning:
<dl>
  <dt>"{{_}}"</dt>
  <dd>
    Match anything (i.e. no real validation, only check existence).
  </dd>
  <dt>"{{unexpected}}"</dt>
  <dd>
    Match nothing (i.e. no real validation, only check lack of existence)
  </dd>
  <dt>
    "{{&gt;key}}"</dt>
  <dd>
    Store value of the whole string (key must be unique within testcase)
  </dd>
  <dt>"{{&lt;key}}"</dt>
  <dd>
    Recall stored value.
  </dd>
</dl>

The "{{_}}" tag can also be used as a JSON object's property in order to
validate any other additional properties.

By default, the builtin validator will allow additional fields in an object
structure. To counteract that default, one can add `"{{_}}": "{{unexpected}}"`
inside the object, effectively making a rule no other properties beyond the
ones defined are expected.


## Examples

```coffeescript
katt = require 'katt'
scenario = './doc/example-httpbin.apib'
params =
  hostname: 'httpbin.org'
  my_name: 'Joe'
  your_name: 'Mike'
katt.run {scenario, params}, (err, result ) ->
  console.log result
```


## Interface

* `katt.run` to be called async with
  * `scenario`
  * `params` (optional)
    * `protocol`
    * `hostname`
    * `port`
    * `requestTimeout`
    * `scenarioTimeout`
  * `callbacks` (optional)
    * `recall` to be called with `scope`, `input`, `params`, `callbacks`
    * `parse` to be called with `headers`, `body`, `params`, `callbacks`
    * `request` to be called async with `request`, `params`, `callbacks`
    * `validate` to be called async with `actual`, `expected`, `params`, `callbacks`


## Contributing

A pull-request is most welcome. Please make sure that the following criteria are
fulfilled before making your pull-request:

* Include a description regarding what has been changed and why.
* Make sure that the changed or added functionality (if you modify code) is
  covered by unit tests.
* Make sure that all unit tests pass.


## License

[Apache 2.0](LICENSE)
