expect  = require 'expect.js'
path    = require 'path'
_s      = require 'underscore.string'
support = require path.resolve(__dirname, '..', 'support')
view    = require path.resolve(__dirname, '..', '..', 'src', 'views', 'list')
helpers = require path.resolve(__dirname, '..', '..', 'src', 'helpers')

describe 'views', ->
  describe 'merge-request-list', ->
    [
      helpers.gitlabEndpoint,
      helpers.githubEndpoint
    ].forEach (endpoint) ->
      describe endpoint.name, ->
        # inject the api stubs
        support["enable#{_s.capitalize(endpoint.name)}ApiStubs"].call this, endpoint

        describe 'with a stubbed api', ->

          # this will actually do the testing
          afterEach (done) ->
            msg =
              reply: (greeting) =>
                expect(greeting).to.equal(@greeting)
              send: (content) =>
                expect(content).to.equal(@content)
                done()

            view.render msg, endpoint, @scope

          beforeEach ->
            if endpoint.name == 'gitlab'
              @greeting = 'Searching for merge requests on gitlab ...'

              @stubApiFor "/api/v3/projects", null, [
                support.fixtures.gitlab.project(id: 1, path_with_namespace: 'company/project1'),
                support.fixtures.gitlab.project(id: 2, path_with_namespace: 'company/project2')
              ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [
                support.fixtures.gitlab.mergeRequest(state: 'merged', title: 'urgent thing'),
                support.fixtures.gitlab.mergeRequest(id: 2)
              ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
              @stubApiFor "/api/v3/projects/2/merge_requests?page=1", null, []
            else
              @greeting = 'Searching for pull requests on github ...'
              @stubApiFor '/user/orgs', null, []
              @stubApiFor '/user/repos', {"page":1,"per_page":100}, null, [
                support.fixtures.github.project(id: 1, full_name: 'company/project1'),
                support.fixtures.github.project(id: 2, full_name: 'company/project2')
              ]
              @stubApiFor '/user/repos', {"page":2,"per_page":100}, null, []
              @stubApiFor "/repos/company/project1/pulls", {page: 1, per_page: 100}, null, [
                support.fixtures.github.pullRequest(state: 'merged', title: 'urgent thing'),
                support.fixtures.github.pullRequest(id: 2)
              ]
              @stubApiFor "/repos/company/project1/pulls", {page: 2, per_page: 100}, null, []
              @stubApiFor "/repos/company/project2/pulls", {page: 1, per_page: 100}, null, []

          describe "without a specific scope", ->
            it 'returns only the open merge requests', ->
              @scope   = null
              @content = '/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing\n12 » opened » unassigned » this merge request makes things better'

          describe "with 'merged' scope", ->
            it 'returns only the merged merge requests', ->
              @scope   = 'merged'
              @content = '/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing'

          describe "with '*' scope", ->
            it 'returns all merge requests', ->
              @scope   = '*'
              @content = '/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing\n12 » opened » unassigned » this merge request makes things better'
