expect  = require 'expect.js'
path    = require 'path'
support = require path.resolve(__dirname, '..', 'support')
view    = require path.resolve(__dirname, '..', '..', 'src', 'views', 'list')
helpers = require path.resolve(__dirname, '..', '..', 'src', 'helpers')

describe 'views', ->
  describe 'merge-request-list', ->
    beforeEach ->
      support.cleanUpEnvironment()

      this.stubApiFor "/api/v3/projects", null, [
        support.fixtures.gitlab.project(id: 1, path_with_namespace: 'company/project1'),
        support.fixtures.gitlab.project(id: 2, path_with_namespace: 'company/project2')
      ]
      this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [
        support.fixtures.gitlab.mergeRequest(state: 'merged', title: 'urgent thing'),
        support.fixtures.gitlab.mergeRequest(id: 2)
      ]
      this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
      this.stubApiFor "/api/v3/projects/2/merge_requests?page=1", null, []

    describe "without a specific scope", ->
      it 'returns only the open merge requests', (done) ->
        view.render helpers.gitlabEndpoint, null, (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing\n12 » opened » unassigned » this merge request makes things better')
          done()

    describe "with 'merged' scope", ->
      it 'returns only the merged merge requests', (done) ->
        view.render helpers.gitlabEndpoint, 'merged', (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing')
          done()

    describe "with '*' scope", ->
      it 'returns all merge requests', (done) ->
        view.render helpers.gitlabEndpoint, '*', (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n11 » merged » unassigned » urgent thing\n12 » opened » unassigned » this merge request makes things better')
          done()
