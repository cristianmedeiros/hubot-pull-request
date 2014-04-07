expect  = require 'expect.js'
path    = require 'path'
_s      = require 'underscore.string'
support = require path.resolve(__dirname, '..', 'support')
view    = require path.resolve(__dirname, '..', '..', 'src', 'views', 'assign')
helpers = require path.resolve(__dirname, '..', '..', 'src', 'helpers')

describe 'views', ->
  describe 'assign', ->
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

            view.render msg, endpoint, @needle, @requestId

          beforeEach ->
            if endpoint.name == 'gitlab'
              @greeting  = 'Assigning merge request #11 of company/project-1 ...'
              @needle    = 'company/project-1'
              @requestId = 11

              @stubApiFor "/api/v3/projects", null, [ support.fixtures.gitlab.project() ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [ support.fixtures.gitlab.mergeRequest() ]
              @stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
              @stubApiFor "/api/v3/groups/1", null, id: 1, name: 'company'
              @stubApiFor "/api/v3/groups/1/members", null, [ id: 1 ]
              @stubApiFor "/api/v3/projects/1/members", null, [ id: 1 ]
              @stubApiFor "/api/v3/projects/1/merge_request/1?assignee_id=1", null, support.fixtures.gitlab.mergeRequest(assignee: { username: 'sdepold' })
            else
              @greeting = 'Assigning pull request #1 of company/project-1 ...'
              @needle    = 'company/project-1'
              @requestId = 1

              @stubGithubApiFor 'get',  '/user/orgs', null, null, [ id: 1, login: 'company' ]
              @stubGithubApiFor 'get',  '/orgs/company/repos', { page: 1, per_page: 100 }, null, [ support.fixtures.github.project( owner: { id: 1, type: 'Organization' } ) ]
              @stubGithubApiFor 'get',  '/orgs/company/repos', { page: 2, per_page: 100 }, null, []
              @stubGithubApiFor 'get',  '/user/repos', { page: 1, per_page: 100 }, null, [ support.fixtures.github.project( id: 2, full_name: 'user/project-1' ) ]
              @stubGithubApiFor 'get',  '/user/repos', { page: 2, per_page: 100 }, null, []
              @stubGithubApiFor 'get',  '/repos/company/project-1/pulls/1', null, null, support.fixtures.github.pullRequest()
              @stubGithubApiFor 'get',  'repos/company/project-1/collaborators', null, null, [ support.fixtures.github.user() ]
              @stubGithubApiFor 'get',  '/repos/company/project-1/issues/1', null, null, support.fixtures.github.pullRequest()
              @stubGithubApiFor 'post', '/repos/company/project-1/issues/11', { assignee: "sdepold" }, null, support.fixtures.github.pullRequest( assignee: { username: 'sdepold' } )

          describe "without a specific scope", ->
            it 'returns only the open merge requests', ->
              @content = 'Successfully assigned the merge request \'this merge request makes things better\' to sdepold.'
