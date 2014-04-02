expect  = require 'expect.js'
path    = require 'path'
support = require path.resolve(__dirname, '..', 'support')
helpers = require path.resolve(__dirname, '..', '..', 'src', 'helpers', 'index')

describe 'helpers', ->
  describe 'index', ->
    beforeEach ->
      support.cleanUpEnvironment()

    it 'does not contain a reference to index', ->
      expect(helpers).to.not.have.key('index')

    it 'contains references to all other helpers', ->
      expect(helpers).to.have.keys('checkConfigs', 'getConfigs', 'gitlabEndpoint')
