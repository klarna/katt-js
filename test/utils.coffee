{
  _
  should
} = require './_utils'
{
  utils
} = require '../'


describe 'utils', () ->
  describe 'isPlainObjectOrArray', () ->

  describe 'regexEscape', () ->

  describe 'isJsonBody', () ->

  describe 'maybeJsonBody', () ->

  describe 'normalizeHeaders', () ->

  describe 'normalizeUrl', () ->

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
