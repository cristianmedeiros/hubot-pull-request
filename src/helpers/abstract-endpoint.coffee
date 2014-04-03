path    = require 'path'
Project = require path.resolve __dirname, '..', 'models', 'project'

methodMissing = (methodName) ->
  throw new Error("The method '#{methodName}' is not implemented!")

module.exports =
  readMergeRequests: (callback) ->
    methodMissing('readMergeRequests')

  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    methodMissing('assignMergeRequest')

  _readMergeRequestPageFor: (project, page, callback) ->
    methodMissing('_readMergeRequestPageFor')

  #
  # readMergeRequestsFor - Returns merge requests for a project.
  #
  # Parameters:
  # - project: An instance of Project.
  # - callback: A function that gets called, once the result is in place.
  #
  _readMergeRequestsFor: (project, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    mergeRequests = []
    page          = 1

    _callback = (err, requests) =>
      if (err)
        callback(err, null)
      else if requests.length == 0
        callback(null, mergeRequests)
      else if page == 100
        callback(new Error('Just iterated to page 100 ... Something is strange!'))
      else
        page += 1
        mergeRequests = mergeRequests.concat requests
        @_readMergeRequestPageFor project, page, _callback

    @_readMergeRequestPageFor project, page, _callback
