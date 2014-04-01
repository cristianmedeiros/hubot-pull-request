expect       = require 'expect.js'
path         = require 'path'
support      = require path.resolve(__dirname, '..', 'support')
checkConfigs = require path.resolve(__dirname, '..', '..', 'src', 'helpers', 'check-configs')

describe 'helpers', ->
  describe 'checkConfigs', ->
    beforeEach ->
      support.cleanUpEnvironment()

    it 'throws an error if no configurations are available', ->
      expect(->
        checkConfigs()
      ).to.throwError(/No hubot configuration/)

    it 'does not throw an error if configurations are available', ->
      expect(->
        process.env.HUBOT_PULL_REQUEST_OM_NOM = 1
        checkConfigs()
      ).to.not.throwError()
