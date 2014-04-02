expect   = require 'expect.js'
path     = require 'path'
support  = require path.resolve __dirname, '..', 'support'
abstract = require path.resolve __dirname, '..', '..', 'src', 'helpers', 'abstract-endpoint'

describe 'helpers', ->
  describe 'abstractEndpoint', ->
    beforeEach ->
      support.cleanUpEnvironment()

    [
      'assignMergeRequest',
      'assignMergeRequestTo',
      'readProjectMembers',
      'readGroupMembers',
      'readGroup',
      'searchProject',
      'readMergeRequests',
      'readMergeRequestViaPublicId',
      'readMergeRequest',
      'readMergeRequestsFor',
      'readMergeRequestPageFor',
      'readProjects',
      'callApi',
      'generateRequestOptions'
    ].forEach (functionName) ->
      describe functionName, ->
        it "throws an error", ->
          expect(->
            abstract[functionName]()
          ).to.throwError(/is not implemented/)
