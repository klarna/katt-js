# KATT(js)

KATT (Klarna API Testing Tool) is an HTTP-based testing tool for NodeJS.


## Quick start

Use for shooting HTTP requests in a sequential order and verifying the response.
Any relevant difference between expected and actual responses will cause a
failure.

Tags with special meaning:
<dl>
  <dt>"{{_}}"</dt>
  <dd>
    Match anything (i.e. no real validation, only check existence)</dd>
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


## Examples

TODO


## License

[Apache 2.0](LICENSE)
