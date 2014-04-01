expect       = require 'expect.js'
path         = require 'path'
sinon        = require 'sinon'
support      = require path.resolve __dirname, '..', 'support'
gitlab       = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'gitlab'
Project      = require path.resolve __dirname, '..', '..', 'src', 'models', 'project'
MergeRequest = require path.resolve __dirname, '..', '..', 'src', 'models', 'merge-request'

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
      it 'throws an error if no instance of Project is passed', ->
        expect(->
          gitlab.readMergeRequestPageFor id: 1, 1, ->
        ).to.throwError(/no instance of Project/)

      it 'reads the merge requests for the correct project and the correct page', (done) ->
        stub    = this.stubApi null, []
        project = new Project id: 2

        gitlab.readMergeRequestPageFor project, 3, ->
          expect(stub.firstCall.args[0]).to.equal('/api/v3/projects/2/merge_requests?page=3')
          done()

      it 'returns MergeRequest instances', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}, {}, {}]

        project = new Project id: 1

        gitlab.readMergeRequestPageFor project, 1, (err, mergeRequests) ->
          expect(mergeRequests).to.have.length(3)
          mergeRequests.forEach (mergeRequest) ->
            expect(mergeRequest).to.be.a(MergeRequest)
          done()

    describe 'readMergeRequestFor', ->
      it 'propagates an error if one occurred', (done) ->
        stub    = this.stubApi new Error('omnom'), null
        project = new Project id: 1

        gitlab.readMergeRequestFor project, (err, result) ->
          expect(err).to.be.an(Error)
          done()

      it 'returns the result set if no further merge requests are available', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}, {}, {}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, [{}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=3", null, []

        project = new Project id: 1

        gitlab.readMergeRequestFor project, (err, result) ->
          expect(err).to.be(null)
          expect(result).to.have.length(4)
          done()

      it 'returns an error if the result set has more than 100 pages', (done) ->
        [1..100].forEach (i) =>
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=#{i}", null, [{}]

        project = new Project id: 1

        gitlab.readMergeRequestFor project, (err, result) ->
          expect(err).to.be.an(Error)
          done()

      it 'returns an empty array if there are no merge requests for this project', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, []

        project = new Project id: 1

        gitlab.readMergeRequestFor project, (err, result) ->
          expect(err).to.be(null)
          expect(result).to.have.length(0)
          done()

    describe 'readMergeRequests', ->
      describe 'without any projects', ->
        beforeEach ->
          this.stubApiFor "/api/v3/projects", null, []

        it 'returns an empty array', (done) ->
          gitlab.readMergeRequests (err, mergeRequests) ->
            expect(mergeRequests).to.be.an(Array)
            expect(mergeRequests).to.have.length(0)
            done()

      describe 'with one project', ->
        beforeEach ->
          this.stubApiFor "/api/v3/projects", null, [id: 1]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []

        it "returns an array with one item", (done) ->
          gitlab.readMergeRequests (err, mergeRequests) ->
            expect(mergeRequests).to.be.an(Array)
            expect(mergeRequests).to.have.length(1)
            expect(support.toJSON(mergeRequests)).to.eql([{
              project:  { id: 1 },
              requests: [{}]
            }])
            done()

      describe 'with multiple projects', ->
        beforeEach ->
          this.stubApiFor "/api/v3/projects", null, [{id: 1}, {id: 2}]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
          this.stubApiFor "/api/v3/projects/2/merge_requests?page=1", null, []

        it "returns an array with multiple items", (done) ->
          gitlab.readMergeRequests (err, mergeRequests) ->
            expect(support.toJSON(mergeRequests)).to.eql([{
              project:  { id: 1 },
              requests: [{}]
            }, {
              project:  { id: 2 },
              requests: []
            }])
            done()

    describe 'readMergeRequest', ->
      beforeEach ->
        this.stubApiFor "/api/v3/projects/1/merge_requests/1", null, {
          id: 1,
          state: 'merged',
          title: 'omg this is urgent'
        }
        this.stubApiFor "/api/v3/projects/1/merge_requests/2", null, null

      it 'returns the merge request if available', (done) ->
        project = new Project(id: 1)

        gitlab.readMergeRequest project, 1, (err, mergeRequest) ->
          expect(err).to.be(null)
          expect(mergeRequest).to.be.a(MergeRequest)
          expect(mergeRequest.id).to.equal(1)
          done()

      it 'returns an error if no merge request was available', (done) ->
        project = new Project(id: 1)

        gitlab.readMergeRequest project, 2, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/Unable to find merge request #2/)
          done()


    describe 'searchProject', ->
      beforeEach ->
        this.stubApiFor "/api/v3/projects", null, [
          {id: 1, path_with_namespace: 'company/project-1'},
          {id: 2, path_with_namespace: 'company/project-2'}
        ]

      it 'throws an error if no projects are matching', (done) ->
        gitlab.searchProject 'company/project-3', (err, project) ->
          expect(err).to.match(/Unable to find a project that matches/)
          done()

      it 'throws an error if multiple projects are matching', (done) ->
        gitlab.searchProject 'company', (err, project) ->
          expect(err).to.match(/Multiple projects have been found for/)
          done()

      it 'returns a single project if only one match is present', (done) ->
        gitlab.searchProject 'project-1', (err, project) ->
          expect(err).to.be(null)
          expect(project).to.be.a(Project)
          expect(project.displayName).to.equal('company/project-1')
          done()
