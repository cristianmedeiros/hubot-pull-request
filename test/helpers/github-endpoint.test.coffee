expect       = require 'expect.js'
path         = require 'path'
sinon        = require 'sinon'
_            = require 'lodash'
_s           = require 'underscore.string'
support      = require path.resolve __dirname, '..', 'support'
abstract     = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'abstract-endpoint'
github       = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'github-endpoint'
Project      = require path.resolve __dirname, '..', '..', 'src', 'models', 'project'
MergeRequest = require path.resolve __dirname, '..', '..', 'src', 'models', 'merge-request'
Group        = require path.resolve __dirname, '..', '..', 'src', 'models', 'group'
User         = require path.resolve __dirname, '..', '..', 'src', 'models', 'user'

describe 'helpers', ->
  describe 'githubEndpoint', ->
    beforeEach ->
      support.cleanUpEnvironment()

      this.recoverApi = =>
        if !!this.stub
          this.stub = undefined
          this.apiStubs = undefined
          github.github.get.restore()

      this.stubApi = (err, result) =>
        process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_USERNAME ||= 'username'
        process.env.HUBOT_PULL_REQUEST_GITHUB_AUTH_PASSWORD ||= 'password'

        this.stub ||= sinon.stub github.github, 'get', =>
          args     = [].slice.apply(arguments)
          path     = args[0]
          options  = if args.length > 2 then args[1] else null
          callback = args[args.length - 1]
          stub     = (this.apiStubs || {})[path + JSON.stringify(options)]

          if !!stub && (!stub.filter || JSON.stringify(options) == JSON.stringify(stub.filter))
            setTimeout((=>
              err     = stub.error
              status  = if !!err then 404 else 200
              body    = stub.result
              headers = {}

              callback err, status, body, headers
            ), 10)
          else
            console.log "Unsure what to do with the route '#{path}' <-> #{JSON.stringify(options)}."
            setTimeout((-> callback(err, result)), 10)

      this.stubApiFor = (path, filter, err, result) =>
        args = [].slice.apply(arguments)

        if args.length == 3
          result = err
          err    = filter
          filter = null

        this.stubApi()
        this.apiStubs ||= {}
        this.apiStubs[path + JSON.stringify(filter)] = { error: err, result: result, filter: filter }

    afterEach ->
      this.recoverApi()

    # support.ensureEndpointImplementation.call this, abstract, github

    describe '_generateRequestOptions', ->
      describe 'without environment variables', ->
        it 'throws an error', ->
          expect(->
            github._generateRequestOptions()
          ).to.throwError(/no configuration for github/)

      describe 'with type, username, password', ->
        beforeEach ->
          @stubApi()
          @requestOptions = github._generateRequestOptions()

        it 'uses api v3', ->
          expect(@requestOptions.version).to.equal('3.0.0')

        it 'returns the correct headers with the respective api token', ->
          expect(@requestOptions.auth).to.eql(
            username: 'username'
            password: 'password'
          )

    describe 'github', ->
      beforeEach ->
        @stubApi()
        @githubInstance = github.github

      it 'contains auth information', ->
        expect(@githubInstance.token).to.eql(
          username: 'username'
          password: 'password'
        )

    describe '_readGroups', ->
      beforeEach ->
        @stubApiFor '/user/orgs', null, [ { id: 1 } ]

      it 'returns instances of Group', (done) ->
        github._readGroups (err, orgs) ->
          expect(err).to.be(null)
          expect(orgs).to.be.an(Array)

          orgs.forEach (org) ->
            expect(org).to.be.a(Group)

          done()

    describe 'readMergeRequests', ->
      beforeEach ->
        @stubApiFor '/user/orgs', null, [ id: 1, login: 'company' ]
        @stubApiFor '/orgs/company/repos', { page: 1, per_page: 100 }, null, [
          support.fixtures.github.project( owner: { id: 1, type: 'Organization' } )
        ]
        @stubApiFor '/orgs/company/repos', { page: 2, per_page: 100 }, null, []
        @stubApiFor '/user/repos', { page: 1, per_page: 100 }, null, [
          support.fixtures.github.project( id: 2, full_name: 'user/project-1' )
        ]
        @stubApiFor '/user/repos', { page: 2, per_page: 100 }, null, []
        @stubApiFor '/repos/company/project-1/pulls', { page: 1, per_page:100 }, null, [ id: 1, state: 'open' ]
        @stubApiFor '/repos/company/project-1/pulls', { page: 2, per_page:100 }, null, []
        @stubApiFor '/repos/user/project-1/pulls', { page: 1, per_page:100 }, null, [ id: 1, state: 'open' ]
        @stubApiFor '/repos/user/project-1/pulls', { page: 2, per_page:100 }, null, []

      it 'returns instances of MergeRequest', (done) ->
        github.readMergeRequests (err, mergeRequests) ->
          expect(err).to.be(null)
          expect(mergeRequests).to.be.an(Array)
          expect(mergeRequests).to.have.length(2)

          mergeRequests.forEach (mergeRequest) ->
            expect(mergeRequest).to.be.a(MergeRequest)

          done()

      it 'returns only open MergeRequests by default', (done) ->
        github.readMergeRequests (err, mergeRequests) ->
          mergeRequests.forEach (mergeRequest) ->
            expect(mergeRequest.state).to.equal('open')
          done()

    describe '_readProjects', ->
      beforeEach ->
        @stubApiFor '/user/orgs', null, [ id: 1, login: 'company' ]
        @stubApiFor '/orgs/company/repos', { page: 1, per_page: 100 }, null, [
          support.fixtures.github.project( owner: { id: 1, type: 'Organization' } )
        ]
        @stubApiFor '/orgs/company/repos', { page: 2, per_page: 100 }, null, []
        @stubApiFor '/user/repos', { page: 1, per_page: 100 }, null, [
          support.fixtures.github.project( id: 2, full_name: 'user/project-1' )
        ]
        @stubApiFor '/user/repos', { page: 2, per_page: 100 }, null, []

      it 'transforms the data into a proper Project instance', (done) ->
        github._readProjects (err, projects) =>
          expect(projects).to.be.an(Array)
          expect(projects.length).to.be.greaterThan(0)

          projects.forEach (project) ->
            expect(project).to.be.a(Project)

          done()

    describe '_readMergeRequestPageFor', ->
      it "throws an error if the passed argument is no Project", ->
        expect(->
          github._readMergeRequestPageFor id: 1
        ).to.throwError(/no instance of Project/)
