path    = require 'path'

support = module.exports =
  _:         require 'lodash'
  _s:        require 'underscore.string'
  sinon:     require 'sinon'
  expect:    require 'expect.js'
  fixtures:  require path.resolve(__dirname, 'support', 'fixtures')
  factories: require path.resolve(__dirname, 'support', 'factories')

  enableGithubApiStubs: (github) ->
    fn = require path.resolve(__dirname, 'support', 'github-api-stub')
    fn.call this, github

  enableGitlabApiStubs: (gitlab) ->
    fn = require path.resolve(__dirname, 'support', 'gitlab-api-stub')
    fn.call this, gitlab

  cleanUpEnvironment: ->
    keys = Object.keys process.env

    keys.forEach (key) ->
      if key.indexOf 'HUBOT_PULL_REQUEST' == 0
        delete process.env[key]

  ensureEndpointImplementation: (abstract, endpoint) ->
    describe 'inheritance', ->
      beforeEach ->
        @mock = support.sinon.mock(endpoint)
        @mock.expects('_methodMissing').never()

      afterEach ->
        @mock.verify()

      Object.keys(abstract).forEach (methodName) ->
        unless methodName == '_methodMissing'
          it "implemented #{methodName}", ->
            support.expect(endpoint[methodName].toString()).to.not.contain("methodMissing")

      it "only reveils the public methods of the abstract endpoint", ->
        publicAbstractMethodNames = Object.keys(abstract)

        Object.keys(endpoint).forEach (methodName) ->
          unless support._.contains publicAbstractMethodNames, methodName
            support.expect(support._s.startsWith(methodName, '_')).to.be.ok()

  toJSON: (obj) ->
    JSON.parse(JSON.stringify(obj))
