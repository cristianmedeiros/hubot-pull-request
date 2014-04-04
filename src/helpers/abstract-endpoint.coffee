_       = require 'lodash'
path    = require 'path'
async   = require 'async'
Project = require path.resolve __dirname, '..', 'models', 'project'

methodMissing = (methodName) ->
  throw new Error("The method '#{methodName}' is not implemented!")

module.exports =
  #
  # readMergeRequests - Returns merge requests for all project.
  #
  # Parameters:
  # - callback: A function that gets called, once the result is in place.
  #
  # Result:
  # - An array of Objects with:
  #   - project: Project
  #   - requests: An array of merge requests
  #
  readMergeRequests: (callback) ->
    @_readProjects (err, projects) =>
      if err
        callback(err, null)
      else
        async.map(
          projects,
          (project, callback) =>
            @_readMergeRequestsFor project, (err, requests) ->
              callback(err, requests)
          (err, requests) ->
            if err
              callback err, null
            else
              callback null, _.flatten(requests)
        )

  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    methodMissing('assignMergeRequest')

  _readMergeRequestPageFor: (project, page, callback) ->
    methodMissing('_readMergeRequestPageFor')

  _readProjects: (callback) ->
    methodMissing('_readProjects')

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
