expect  = require 'expect.js'
path    = require 'path'
support = require path.resolve(__dirname, '..', 'support')
gitlab  = require path.resolve(__dirname, '..', '..', 'src', 'helpers', 'gitlab')

describe 'helpers', ->
  describe 'gitlab', ->
    beforeEach ->
      support.cleanUpEnvironment()

    describe 'generateRequestOptions', ->
      describe 'without environment variables', ->
        it 'throws an error', ->
          expect(->
            gitlab.generateRequestOptions '/api/v3/projects'
          ).to.throwError(/no configuration for gitlab/)

      describe 'with gitlab host and api key', ->
        beforeEach ->
          process.env.HUBOT_PULL_REQUEST_GITLAB_HOST = 'http://localhost:1234'
          process.env.HUBOT_PULL_REQUEST_GITLAB_API_TOKEN = '123456789'

          @requestOptions = gitlab.generateRequestOptions '/api/v3/projects'

        it 'returns the correct url', ->
          expect(@requestOptions.url).to.equal('http://localhost:1234/api/v3/projects')

        it 'returns the correct headers with the respective api token', ->
          expect(@requestOptions.headers).to.only.have.key('PRIVATE-TOKEN')
          expect(@requestOptions.headers['PRIVATE-TOKEN']).to.equal('123456789')

      describe 'with basic auth', ->
        beforeEach ->
          process.env.HUBOT_PULL_REQUEST_GITLAB_HOST = 'http://localhost:1234'
          process.env.HUBOT_PULL_REQUEST_GITLAB_API_TOKEN = '123456789'
          process.env.HUBOT_PULL_REQUEST_GITLAB_BASIC_AUTH_USERNAME = 'user'
          process.env.HUBOT_PULL_REQUEST_GITLAB_BASIC_AUTH_PASSWORD = 'pass'

          @requestOptions = gitlab.generateRequestOptions '/api/v3/projects'

        it 'returns the correct basic auth options', ->
          expect(@requestOptions.auth).to.eql(
            user: 'user',
            pass: 'pass'
          )
