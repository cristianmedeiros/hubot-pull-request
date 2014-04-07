_         = require 'lodash'
_s        = require 'underscore.string'
path      = require 'path'
async     = require 'async'
Project   = require path.resolve __dirname, '..', 'models', 'project'
getConfig = require path.resolve __dirname, '..', 'helpers', 'get-config'

module.exports =
  name: 'abstract'

  #
  # getPaginationBorder - Returns the highest page number for pagination.
  #
  # Can be set via the environment variable HUBOT_PULL_REQUEST_PAGINATION_BORDER.
  # Default: 100
  #
  getPaginationBorder: ->
    config      = getConfig()
    configValue = config.pagination && config.pagination.border
    parseInt(configValue || 100)

  #
  # getPerPage - Returns the number of items per paginated page.
  #
  # Can be set with the environment variable HUBOT_PULL_REQUEST_PAGINATION_PER_PAGE.
  # Default: 100
  #
  getPerPage: ->
    config      = getConfig()
    configValue = config.pagination && config.pagination.per && config.pagination.per.page
    parseInt(configValue || 100)

  #
  # readMergeRequests - Returns merge requests for all projects.
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
        callback err, null
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
    @_methodMissing 'assignMergeRequest'

  _readMergeRequestPageFor: (project, page, callback) ->
    @_methodMissing '_readMergeRequestPageFor'

  _readProjects: (callback) ->
    @_methodMissing '_readProjects'

  _methodMissing: (methodName) ->
    throw new Error("The method '#{methodName}' is not implemented!")

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
        callback err, null
      else if requests.length == 0
        callback null, mergeRequests
      else if page == @getPaginationBorder()
        callback new Error('Just iterated to page 100 ... Something is strange!'), null
      else
        page += 1
        mergeRequests = mergeRequests.concat requests
        @_readMergeRequestPageFor project, page, _callback

    @_readMergeRequestPageFor project, page, _callback

  #
  # searchProject - Returns a project that matches the passed needle.
  #
  # It will return the project with an exact match if there are multiple
  # matching projects. Example:
  #
  # Premise - The following projects exist:
  #
  # - sdepold/node-imageable
  # - sdepold/node-imageable-server
  #
  # A search for `node-imageable` will result in an error as there is no exact
  # match. A search for `sdepold/node-imageable` will use the respective repo.
  #
  # Parameters:
  # - needle: A string that gets searched for in the project names.
  # - callback: A function that gets called, once the result is in place.
  #
  _searchProject: (needle, callback) ->
    @_readProjects (err, projects) =>
      if err
        callback err, null
      else
        project  = null
        projects = projects.filter (project) -> project.hasName(needle)
        projects = _.sortBy projects, (_project) ->
          distance = _s.levenshtein(_project.displayName, needle)
          project  = _project if distance == 0
          distance

        if projects.length == 0
          callback new Error("Unable to find a project that matches '#{needle}'."), null
        else if !project && projects.length > 1
          message = "Multiple projects have been found for '#{needle}'."

          projects.forEach (project) ->
            message += "\n- #{project.displayName}"

          callback new Error(message), null
        else
          callback null, project || projects[0]
