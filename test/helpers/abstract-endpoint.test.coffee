expect   = require 'expect.js'
path     = require 'path'
support  = require path.resolve __dirname, '..', 'support'
abstract = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'abstract-endpoint'

describe 'helpers', ->
  describe 'abstractEndpoint', ->
    beforeEach ->
      support.cleanUpEnvironment()

    describe 'getPaginationBorder', ->
      it "defaults to 100", ->
        expect(abstract.getPaginationBorder()).to.equal(100)

      it "takes the environment variable HUBOT_PULL_REQUEST_PAGINATION_BORDER into account", ->
        process.env.HUBOT_PULL_REQUEST_PAGINATION_BORDER = 10
        expect(abstract.getPaginationBorder()).to.equal(10)

    describe 'getPerPage', ->
      it "defaults to 100", ->
        expect(abstract.getPerPage()).to.equal(100)

      it "takes the environment variable HUBOT_PULL_REQUEST_PAGINATION_PER_PAGE into account", ->
        process.env.HUBOT_PULL_REQUEST_PAGINATION_PER_PAGE = 10
        expect(abstract.getPerPage()).to.equal(10)
