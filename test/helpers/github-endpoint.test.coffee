expect       = require 'expect.js'
path         = require 'path'
sinon        = require 'sinon'
support      = require path.resolve __dirname, '..', 'support'
github       = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'github-endpoint'
Project      = require path.resolve __dirname, '..', '..', 'src', 'models', 'project'
MergeRequest = require path.resolve __dirname, '..', '..', 'src', 'models', 'merge-request'
Group        = require path.resolve __dirname, '..', '..', 'src', 'models', 'group'
User         = require path.resolve __dirname, '..', '..', 'src', 'models', 'user'


describe 'helpers', ->
  describe 'githubEndpoint', ->
    # describe 'implemented methods', ->
    #   it 'implemented them all', ->
    #     Object.keys(github).forEach (methodName) ->
    #       expect(->
    #         github[methodName]()
    #       ).to.not.throwError(/is not implemented/)

    describe 'generateRequestOptions', ->
      describe 'without environment variables', ->
        it 'throws an error', ->
          expect(->
            github.generateRequestOptions()
          ).to.throwError(/no configuration for github/)

      describe 'with type, username, password', ->
        beforeEach ->
          process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_TYPE = 'basic'
          process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME = 'a user'
          process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD = 'a password'

          @requestOptions = github.generateRequestOptions()

        it 'uses api v3', ->
          console.log @requestOptions
          expect(@requestOptions.version).to.equal('3.0.0')

        # it 'returns the correct headers with the respective api token', ->
        #   console.log @requestOptions
        #   expect(@requestOptions.auth).to.eql(
        #     type: 'basic'
        #     username: 'a user'
        #     password: 'a password'
        #   )
