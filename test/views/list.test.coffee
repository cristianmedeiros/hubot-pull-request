expect  = require 'expect.js'
path    = require 'path'
support = require path.resolve(__dirname, '..', 'support')
view    = require path.resolve(__dirname, '..', '..', 'src', 'views', 'list')

describe 'views', ->
  describe 'merge-request-list', ->
    beforeEach ->
      support.cleanUpEnvironment()

      this.stubApiFor "/api/v3/projects", null, [
        {id: 1, path_with_namespace: 'company/project1'},
        {id: 2, path_with_namespace: 'company/project2'}
      ]
      this.stubApiFor "/api/v3/projects/1/merge_requests?page=1", null, [
        { id: 1, iid: 11, state: 'merged', title: 'omg this is urgent' },
        { id: 2, iid: 12, state: 'opened', title: 'fixed type' }
      ]
      this.stubApiFor "/api/v3/projects/1/merge_requests?page=2", null, []
      this.stubApiFor "/api/v3/projects/2/merge_requests?page=1", null, []

    describe "without a specific scope", ->
      it 'returns only the open merge requests', (done) ->
        view.render null, (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n12 » opened » unassigned » fixed type')
          done()

    describe "with 'merged' scope", ->
      it 'returns only the merged merge requests', (done) ->
        view.render 'merged', (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n11 » merged » unassigned » omg this is urgent')
          done()

    describe "with '*' scope", ->
      it 'returns all merge requests', (done) ->
        view.render '*', (err, content) ->
          expect(err).to.be(null)
          expect(content).to.equal('/quote company/project1\n----------------\n11 » merged » unassigned » omg this is urgent\n12 » opened » unassigned » fixed type')
          done()
