_           = require 'lodash'
_s          = require 'underscore.string'
path        = require 'path'
async       = require 'async'
Project     = require path.resolve __dirname, '..', 'models', 'project'
getConfig   = require path.resolve __dirname, '..', 'helpers', 'get-config'

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
  # assignMergeRequest - Assigns a merge request to a random project member.
  #
  # Parameters:
  # - projectName: A needle that will be used for searching the relevant projects.
  # - mergeRequestId: An ID of a merge request.
  # - userNames: An array of usernames to choose from - set this to null for the default behaviour (all users).
  # - callback: A function that gets called, once the result is in place.
  #
  assignMergeRequest: (projectName, mergeRequestId, callback, userNames) ->
    serviceName = @name
    async.waterfall [
      (asyncCallback) =>
        @_searchProject projectName, asyncCallback

      (project, asyncCallback) =>
        @_readMergeRequestViaPublicId project, mergeRequestId, (err, mergeRequest) ->
          return asyncCallback(err, null) if err
          return asyncCallback(new Error("The merge request is already #{mergeRequest.state}!"), null) if !mergeRequest.isOpen
          asyncCallback null, project, mergeRequest

      (project, mergeRequest, asyncCallback) =>
        @_readCollaborators project, (err, collaborators) ->
          return asyncCallback(err, null) if err
          
          # If there is a users pool, choose a valid user from there
          console.log userNames
          if !! userNames
            collaboratorNames = collaborators.map((c) -> c.username)
            console.log collaboratorNames
            candidateNames    = _.intersection(userNames, collaboratorNames)
            console.log candidateNames
            if candidateNames.length > 0
              winnerName = _.sample(candidateNames)
              console.log winnerName

              collaborator = _.first(collaborators, (c) -> c.username == winnerName || c.login == winnerName)
            console.log collaborator
          
          # Otherwise, fall back to all collaborators
          collaborator ||= _.sample(collaborators)

          asyncCallback null, project, mergeRequest, collaborator

      (project, mergeRequest, member, asyncCallback) =>
        @_assignMergeRequestTo member, project, mergeRequest, (err, mergeRequest) ->
          return asyncCallback(err, null) if err
          asyncCallback null, mergeRequest
    ], callback

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
        exactMatch = null
        projects   = projects.filter (project) -> project.hasName(needle)
        projects   = _.sortBy projects, (project) ->
          distance   = _s.levenshtein project.displayName, needle
          exactMatch = project if distance == 0
          distance

        if _.isEmpty projects
          callback new Error("Unable to find a project that matches '#{needle}'."), null
        else if !exactMatch && projects.length > 1
          # We have no exact match and the search found more than one entry.
          # Tell the user about the conflict ...

          message = "Multiple projects have been found for '#{needle}'."

          projects.forEach (project) ->
            message += "\n- #{project.displayName}"

          callback new Error(message), null
        else
          # We have either found an exact match or exactly one matching project.
          callback null, exactMatch || projects[0]
