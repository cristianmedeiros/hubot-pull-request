expect   = require 'expect.js'
path     = require 'path'
support  = require path.resolve __dirname, '..', 'support'
abstract = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'abstract-endpoint'

describe 'helpers', ->
  describe 'abstractEndpoint', ->
    beforeEach ->
      support.cleanUpEnvironment()

    [
      'assignMergeRequest'
    ].forEach (functionName) ->
      describe functionName, ->
        it "throws an error", ->
          expect(->
            abstract[functionName]()
          ).to.throwError(/is not implemented/)
