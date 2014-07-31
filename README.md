# KATT(js) [![Build Status][2]][1]

KATT (Klarna API Testing Tool) is an HTTP-based testing tool for Node.


## Quick start

Use for shooting HTTP requests in a sequential order and verifying the response.
Any relevant difference between expected and actual responses will cause a
failure.

The validator makes use of a few tags with special meaning:

`"{{_}}"`  
Match anything (i.e. no real validation, only check existence).

`"{{unexpected}}"`  
Match nothing (i.e. no real validation, only check lack of existence)

`"{{>key}}"`  
Store value of the whole string (key must be unique within testcase)

`"{{<key}}"`  
Recall stored value.

The `"{{_}}"` tag can also be used as a JSON object's property in order to
validate any other additional properties.

By default, the builtin validator will allow additional properties in an object
structure, or additional items in an array structure. To counteract that
default, one can do `{..., "{{_}}": "{{unexpected}}"}` or
`[..., "{{unexpected}}"]`, effectively making a rule that no properties/items
are expected beyond the ones defined.


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


## CLI

```shell
katt-js -p '{"hostname":"httpbin.org","your_name":"Klarna","my_name":"KATT","whoarewe":"Klarna_and_KATT"}' doc/example-httpbin.apib
```


## Contributing

A pull-request is most welcome. Please make sure that the following criteria are
fulfilled before making your pull-request:

* Include a description regarding what has been changed and why.
* Make sure that the changed or added functionality (if you modify code) is
  covered by unit tests.
* Make sure that all unit tests pass.


## License

[Apache 2.0](LICENSE)


  [1]: https://travis-ci.org/klarna/katt-js
  [2]: https://travis-ci.org/klarna/katt-js.png
