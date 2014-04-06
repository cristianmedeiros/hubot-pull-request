expect  = require 'expect.js'
path    = require 'path'
_s      = require 'underscore.string'
support = require path.resolve(__dirname, '..', 'support')
view    = require path.resolve(__dirname, '..', '..', 'src', 'views', 'assign')
helpers = require path.resolve(__dirname, '..', '..', 'src', 'helpers')

describe 'views', ->
  describe 'assign', ->
    [
      helpers.gitlabEndpoint#,
      # helpers.githubEndpoint
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

            view.render msg, endpoint, 'company/project-1', 11

          beforeEach ->
            if endpoint.name == 'gitlab'
              @greeting = 'Assigning merge request #11 of company/project-1 ...'
              @stubApiFor "/api/v3/projects", null, [ support.fixtures.gitlab.project() ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [ support.fixtures.gitlab.mergeRequest() ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
              @stubApiFor "/api/v3/groups/1", null, id: 1, name: 'company'
              @stubApiFor "/api/v3/groups/1/members", null, [ id: 1 ]
              @stubApiFor "/api/v3/projects/1/members", null, [ id: 1 ]
              @stubApiFor "/api/v3/projects/1/merge_request/1?assignee_id=1", null, support.fixtures.gitlab.mergeRequest(assignee: { username: 'omnom' })
            else
              @greeting = 'Assigning pull request #1 of company/project-1 ...'
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
              @content = 'Successfully assigned the merge request \'this merge request makes things better\' to omnom.'
