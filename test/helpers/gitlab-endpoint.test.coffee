expect       = require 'expect.js'
path         = require 'path'
sinon        = require 'sinon'
_            = require 'lodash'
_s           = require 'underscore.string'
support      = require path.resolve __dirname, '..', 'support'
abstract     = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'abstract-endpoint'
gitlab       = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'gitlab-endpoint'
Project      = require path.resolve __dirname, '..', '..', 'src', 'models', 'project'
MergeRequest = require path.resolve __dirname, '..', '..', 'src', 'models', 'merge-request'
Group        = require path.resolve __dirname, '..', '..', 'src', 'models', 'group'
User         = require path.resolve __dirname, '..', '..', 'src', 'models', 'user'

describe 'helpers', ->
  describe 'gitlabEndpoint', ->
    beforeEach ->
      support.cleanUpEnvironment()

      this.recoverApi = =>
        if !!this.stub
          this.stub = undefined
          this.apiStubs = undefined
          gitlab._callApi.restore()

      this.stubApi = (err, result) =>
        this.stub ||= sinon.stub gitlab, '_callApi', (path, callback) =>
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

    describe 'implemented methods', ->
      Object.keys(abstract).forEach (methodName) ->
        it "implemented #{methodName}", ->
          expect(->
            gitlab[methodName]()
          ).to.not.throwError(/is not implemented/)

      it "only reveils the public methods of the abstract endpoint", ->
        publicAbstractMethodNames = Object.keys(abstract)

        Object.keys(gitlab).forEach (methodName) ->
          unless _.contains publicAbstractMethodNames, methodName
            expect(_s.startsWith(methodName, '_')).to.be.ok()

    describe '_generateRequestOptions', ->
      describe 'without environment variables', ->
        it 'throws an error', ->
          expect(->
            gitlab._generateRequestOptions '/api/v3/projects'
          ).to.throwError(/no configuration for gitlab/)

      describe 'with gitlab host and api key', ->
        beforeEach ->
          process.env.HUBOT_PULL_REQUEST_GITLAB_HOST = 'http://localhost:1234'
          process.env.HUBOT_PULL_REQUEST_GITLAB_API_TOKEN = '123456789'

          @requestOptions = gitlab._generateRequestOptions '/api/v3/projects'

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

          @requestOptions = gitlab._generateRequestOptions '/api/v3/projects'

        it 'returns the correct basic auth options', ->
          expect(@requestOptions.auth).to.eql(
            user: 'user',
            pass: 'pass'
          )

    describe '_readProjects', ->
      it 'reads the projects from the API', (done) ->
        stub = this.stubApi null, []

        gitlab._readProjects ->
          expect(stub.firstCall.args[0]).to.equal('/api/v3/projects')
          done()

      it 'transforms the data into a proper Project instance', (done) ->
        @project = support.fixtures.gitlab.project()
        @stubApiFor "/api/v3/projects", null, [ @project ]

        gitlab._readProjects (err, projects) =>
          expect(projects).to.be.an(Array)
          expect(projects).to.have.length(1)
          expect(projects[0]).to.eql(
            displayName: 'company/project-1'
            id:          1
            ownerId:     1
            ownerType:   null
          )
          done()

    describe '_readMergeRequestPageFor', ->
      it 'throws an error if no instance of Project is passed', ->
        expect(->
          gitlab._readMergeRequestPageFor id: 1, 1, ->
        ).to.throwError(/no instance of Project/)

      it 'reads the merge requests for the correct project and the correct page', (done) ->
        stub    = this.stubApi null, []
        project = new Project id: 2

        gitlab._readMergeRequestPageFor project, 3, ->
          expect(stub.firstCall.args[0]).to.equal('/api/v3/projects/2/merge_requests?page=3')
          done()

      it 'returns MergeRequest instances', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}, {}, {}]

        project = new Project id: 1

        gitlab._readMergeRequestPageFor project, 1, (err, mergeRequests) ->
          expect(mergeRequests).to.have.length(3)
          mergeRequests.forEach (mergeRequest) ->
            expect(mergeRequest).to.be.a(MergeRequest)
          done()

    describe '_readMergeRequestsFor', ->
      it 'throws an error if the passed object is no project', ->
        expect(->
          gitlab._readMergeRequestsFor id: 1
        ).to.throwError(/no instance of Project/)

      it 'propagates an error if one occurred', (done) ->
        stub    = this.stubApi new Error('omnom'), null
        project = new Project id: 1

        gitlab._readMergeRequestsFor project, (err, result) ->
          expect(err).to.be.an(Error)
          done()

      it 'returns the result set if no further merge requests are available', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{}, {}, {}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, [{}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=3", null, []

        project = new Project id: 1

        gitlab._readMergeRequestsFor project, (err, result) ->
          expect(err).to.be(null)
          expect(result).to.have.length(4)
          done()

      it 'returns an error if the result set has more than 100 pages', (done) ->
        [1..100].forEach (i) =>
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=#{i}", null, [{}]

        project = new Project id: 1

        gitlab._readMergeRequestsFor project, (err, result) ->
          expect(err).to.be.an(Error)
          done()

      it 'returns an empty array if there are no merge requests for this project', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, []

        project = new Project id: 1

        gitlab._readMergeRequestsFor project, (err, result) ->
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

        it 'propagates api errors', (done) ->
          this.stubApiFor "/api/v3/projects", 'wtf', null

          gitlab.readMergeRequests (err, projects) ->
            expect(err).to.match(/wtf/)
            done()

      describe 'with one project', ->
        beforeEach ->
          @stubApiFor "/api/v3/projects", null, [ support.fixtures.gitlab.project() ]
          @stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{ id: 1 }]
          @stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []

        it "returns an array with one item", (done) ->
          gitlab.readMergeRequests (err, mergeRequests) =>
            expect(mergeRequests).to.be.an(Array)
            expect(mergeRequests).to.have.length(1)
            expect(support.toJSON(mergeRequests)).to.eql([{
              id: 1,
              project: { id: 1, displayName: 'company/project-1', ownerId: 1, ownerType: null }
            }])
            done()

      describe 'with multiple projects', ->
        beforeEach ->
          this.stubApiFor "/api/v3/projects", null, [
            support.fixtures.gitlab.project(id: 1, path_with_namespace: 'company/project-1'),
            support.fixtures.gitlab.project(id: 2, path_with_namespace: 'company/project-2')
          ]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{ id: 1 }]
          this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
          this.stubApiFor "/api/v3/projects/2/merge_requests?page=1", null, []

        it "returns an array with multiple items", (done) ->
          gitlab.readMergeRequests (err, mergeRequests) ->
            expect(mergeRequests).to.be.an(Array)
            expect(mergeRequests).to.have.length(1)

            expect(support.toJSON(mergeRequests)).to.eql([{
              id: 1,
              project: { id: 1, displayName: 'company/project-1', ownerId: 1, ownerType: null }
            }])
            done()

    describe '_readMergeRequest', ->
      beforeEach ->
        this.stubApiFor "/api/v3/projects/1/merge_request/1", null, {
          id: 1,
          state: 'merged',
          title: 'omg this is urgent'
        }
        this.stubApiFor "/api/v3/projects/1/merge_request/2", null, null

      it 'throws an error if the passed object is no project', ->
        expect(->
          gitlab._readMergeRequest id: 1
        ).to.throwError(/no instance of Project/)

      it 'returns the merge request if available', (done) ->
        project = new Project(id: 1)

        gitlab._readMergeRequest project, 1, (err, mergeRequest) ->
          expect(err).to.be(null)
          expect(mergeRequest).to.be.a(MergeRequest)
          expect(mergeRequest.id).to.equal(1)
          done()

      it 'returns an error if no merge request was available', (done) ->
        project = support.factories.project()

        gitlab._readMergeRequest project, 2, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/Unable to find merge request #2/)
          done()

    describe '_searchProject', ->
      beforeEach ->
        this.stubApiFor "/api/v3/projects", null, [
          support.fixtures.gitlab.project(id: 1, path_with_namespace: 'company/project-1'),
          support.fixtures.gitlab.project(id: 2, path_with_namespace: 'company/project-2')
        ]

      it 'propagates api errors', (done) ->
        this.stubApiFor "/api/v3/projects", 'wtf', null

        gitlab._searchProject 'omnom', (err, projects) ->
          expect(err).to.match(/wtf/)
          done()

      it 'throws an error if no projects are matching', (done) ->
        gitlab._searchProject 'company/project-3', (err, project) ->
          expect(err).to.match(/Unable to find a project that matches/)
          done()

      it 'throws an error if multiple projects are matching', (done) ->
        gitlab._searchProject 'company', (err, project) ->
          expect(err).to.match(/Multiple projects have been found for/)
          done()

      it 'returns a single project if only one match is present', (done) ->
        gitlab._searchProject 'project-1', (err, project) ->
          expect(err).to.be(null)
          expect(project).to.be.a(Project)
          expect(project.displayName).to.equal('company/project-1')
          done()

    describe '_readProjectMembers', ->
      it 'throws an error if no project instance is passed', ->
        expect(->
          gitlab._readProjectMembers { id: 1 }
        ).to.throwError(/passed argument is no instance of Project/)

      it 'propagates an error if no users are available', (done) ->
        project = new Project(id: 1)

        this.stubApiFor '/api/v3/projects/1/members', null, []
        gitlab._readProjectMembers project, (err, user) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/No members found/)
          done()

      it 'propagates api call errors', (done) ->
        project = new Project(id: 1)

        this.stubApiFor '/api/v3/projects/1/members', new Error('omg omg omg'), null
        gitlab._readProjectMembers project, (err, user) ->
          expect(err).to.be.an(Error)
          done()

    describe 'assignMergeRequest', ->
      beforeEach ->
        @projects = [{ id: 1, path_with_namespace: 'company/project-1', namespace: { id: 1 } }]
        @stubApiFor '/api/v3/projects', null, @projects

      it 'propagates an error if no such project is available', (done) ->
        gitlab.assignMergeRequest 'company/omnom', 1, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/Unable to find a project that matches/)
          done()

      it 'propagates an error if no merge request is available for that id', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        gitlab.assignMergeRequest 'company/proje', 12, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/to find merge request #12 for project/)
          done()

      it 'propagates an error if reading the group fails', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/groups/1', new Error('ohoh'), null

        gitlab.assignMergeRequest 'project', 11, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/ohoh/)
          done()

      it 'propagates an error if reading the project members fails', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/groups/1', null, { id: 1, projects: @projects }
        this.stubApiFor '/api/v3/projects/1/members', new Error('ohoh'), null

        gitlab.assignMergeRequest 'project', 11, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/ohoh/)
          done()

      it 'propagates an error if reading the group members fails', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/groups/1', null, { id: 1, projects: @projects }
        this.stubApiFor '/api/v3/groups/1/members', new Error('ohoh'), null

        gitlab.assignMergeRequest 'project', 11, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/ohoh/)
          done()

      it 'propagates an error if merge request assignment fails', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/projects/1/members', null, [{ id: 1 }]
        this.stubApiFor '/api/v3/projects/1/merge_request/1?assignee_id=1', 'ohoh', null
        this.stubApiFor '/api/v3/groups/1', null, { id: 1, projects: @projects }
        this.stubApiFor '/api/v3/groups/1/members', null, [{ id: 1, projects: @projects }]

        gitlab.assignMergeRequest 'company/proje', 11, (err, mergeRequest) ->
          expect(err).to.match(/ohoh/)
          done()

      it 'propagates an error about non-open state of the merge request', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'closed' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/projects/1/members', null, [{ id: 1 }]
        this.stubApiFor '/api/v3/projects/1/merge_request/1?assignee_id=1', null, { id: 1, state: 'opened' }
        this.stubApiFor '/api/v3/groups/1', null, { id: 1, projects: @projects }
        this.stubApiFor '/api/v3/groups/1/members', null, [{ id: 1, projects: @projects }]

        gitlab.assignMergeRequest 'company/proje', 11, (err, mergeRequest) ->
          expect(err).to.match(/The merge request is already closed/)
          done()

      it 'just works if everything is nice', (done) ->
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=1', null, [{ id: 1, iid: 11, state: 'opened' }]
        this.stubApiFor '/api/v3/projects/1/merge_requests?page=2', null, []
        this.stubApiFor '/api/v3/projects/1/members', null, [{ id: 1 }]
        this.stubApiFor '/api/v3/projects/1/merge_request/1?assignee_id=1', null, { id: 1, state: 'opened' }
        this.stubApiFor '/api/v3/groups/1', null, { id: 1, projects: @projects }
        this.stubApiFor '/api/v3/groups/1/members', null, [{ id: 1, projects: @projects }]

        gitlab.assignMergeRequest 'company/proje', 11, (err, mergeRequest) ->
          expect(err).to.be(null)
          expect(mergeRequest).to.be.a(MergeRequest)
          done()

    describe '_readMergeRequestViaPublicId', ->
      it 'throws an error if the passed object is no project', ->
        expect(->
          gitlab._readMergeRequestViaPublicId id: 1
        ).to.throwError(/no instance of Project/)

      it 'propagates an error if no merge requests were matching', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{ iid: 11, id: 1}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []

        project = support.factories.project()

        gitlab._readMergeRequestViaPublicId project, 12, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/Unable to find merge request #12 for project 'company\/project-1'/)
          done()

      it 'propagates an error if there were multiple matching merge requests', (done) ->
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [{ iid: 11, id: 1}, { iid: 11, id: 2}]
        this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []

        project = support.factories.project()

        gitlab._readMergeRequestViaPublicId project, 11, (err, mergeRequest) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/Too many merge requests found/)
          done()

    describe '_readGroup', ->
      it 'propagates api errors', (done) ->
        this.stubApiFor "/api/v3/groups/1", 'wtf', null

        gitlab._readGroup 1, (err, group) ->
          expect(err).to.match(/wtf/)
          done()

      it 'generates an error if group has not been found', (done) ->
        this.stubApiFor "/api/v3/groups/1", null, null

        gitlab._readGroup 1, (err, group) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/No group found/)
          done()

    describe '_readGroupMembers', ->
      it 'throws an error if passed argument is no group', ->
        expect(->
          gitlab._readGroupMembers id: 1
        ).to.throwError(/The passed argument is no instance of Group/)

      it 'propagates api errors', (done) ->
        this.stubApiFor "/api/v3/groups/1/members", new Error('some errors'), null
        gitlab._readGroupMembers new Group(id: 1), (err, members) ->
          expect(err).to.be.an(Error)
          expect(err).to.match(/some errors/)
          done()

    describe '_assignMergeRequestTo', ->
      beforeEach ->
        @member       = new User(id: 1)
        @project      = support.factories.project()
        @mergeRequest = new MergeRequest(id: 1)
        @stubApiFor "/api/v3/projects/#{@project.id}/merge_request/#{@mergeRequest.id}?assignee_id=#{@member.id}", 'foo', null

      it 'throws an error if passed argument is no instance of User', ->
        expect(=>
          gitlab._assignMergeRequestTo id: 1
        ).to.throwError(/The passed argument is no instance of User/)

      it 'throws an error if passed argument is no instance of Project', ->
        expect(=>
          gitlab._assignMergeRequestTo @member, id: 1
        ).to.throwError(/The passed argument is no instance of Project/)

      it 'throws an error if passed argument is no instance of MergeRequest', ->
        expect(=>
          gitlab._assignMergeRequestTo @member, @project, id: 1
        ).to.throwError(/The passed argument is no instance of MergeRequest/)

      it 'does not throw if the arguments are instance of the respective class', (done) ->
        gitlab._assignMergeRequestTo @member, @project, @mergeRequest, ->
          done()
