expect  = require 'expect.js'
path    = require 'path'
sinon   = require 'sinon'
support = require path.resolve(__dirname, '..', 'support')
gitlab  = require path.resolve(__dirname, '..', '..', 'src', 'helpers', 'gitlab')

describe 'helpers', ->
  describe 'gitlab', ->
    beforeEach ->
      support.cleanUpEnvironment()

      this.recoverApi = =>
        if !!this.stub
          this.stub = undefined
          this.apiStubs = undefined
          gitlab.callApi.restore()

      this.stubApi = (err, result) =>
        this.stub ||= sinon.stub gitlab, 'callApi', (path, callback) =>
          if (this.apiStubs || {})[path]
            setTimeout((=>
              callback(this.apiStubs[path].error, this.apiStubs[path].result)
            ), 10)
          else
            setTimeout((-> callback(err, result)), 10)

      this.stubApiFor = (path, err, result) =>
        this.stubApi()
        this.apiStubs ||= {}
        this.apiStubs[path] = { error: err, result: result }

    afterEach ->
      this.recoverApi()

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

    describe 'readProjects', ->
      it 'reads the projects from the API', (done) ->
        stub = this.stubApi null, []

        gitlab.readProjects ->
          expect(stub.firstCall.args[0]).to.equal('/api/v3/projects')
          done()

    describe 'readMergeRequestPageFor', ->
      it 'reads the merge requests for the correct project and the correct page', (done) ->
        stub = this.stubApi null, []

        gitlab.readMergeRequestPageFor id: 2, 3, ->
          expect(stub.firstCall.args[0]).to.equal('/api/v3/projects/2/merge_requests?page=3')
          done()

    describe 'readMergeRequestFor', ->
      it 'propagates an error if one occurred', (done) ->
        stub    = this.stubApi new Error('omnom'), null
        project = { id: 1 }

        gitlab.readMergeRequestFor project, (err, result) ->
          expect(err).to.be.an(Error)
          done()

      it 'returns the result set if no further merge requests are available', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}, {}, {}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, [{}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=3", null, []

        gitlab.readMergeRequestFor id: 1, (err, result) ->
          expect(err).to.be(null)
          expect(result).to.have.length(4)
          done()

      it 'returns an error if the result set has more than 100 pages', (done) ->
        [1..100].forEach (i) =>
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=#{i}", null, [{}]

        gitlab.readMergeRequestFor id: 1, (err, result) ->
          expect(err).to.be.an(Error)
          done()
