path         = require 'path'
request      = require 'request'
_            = require 'lodash'
async        = require 'async'

AbstractEndpoint = require path.resolve __dirname, 'abstract-endpoint'
getConfigs       = require path.resolve __dirname, 'get-configs'
Project          = require path.resolve __dirname, '..', 'models', 'project'
MergeRequest     = require path.resolve __dirname, '..', 'models', 'merge-request'
User             = require path.resolve __dirname, '..', 'models', 'user'
Group            = require path.resolve __dirname, '..', 'models', 'group'

module.exports = _.extend {}, AbstractEndpoint,
  #
  # generateRequestOptions - Returns the options for the request call.
  #
  # Parameters:
  # - remotePath: The path to the remote server.
  # - otherOptions: Additional options which gets merged into the result.
  #
  # Result:
  # - Object
  #
  generateRequestOptions: (remotePath, otherOptions={}) ->
    config  = getConfigs().gitlab

    unless config
      throw new Error("There is no configuration for gitlab ...")

    options = {
      url: "#{config.host}#{remotePath}",
      headers:
        'PRIVATE-TOKEN': config.apiToken
    }

    if config.basicAuthUsername && config.basicAuthPassword
      options.auth =
        user: config.basicAuthUsername,
        pass: config.basicAuthPassword

    _.extend(options, otherOptions)

  #
  # callApi - Calls the API and returns its data as a properly transformed object.
  #
  # Parameters:
  # - path: A path on the remote server.
  # - callback: A function that gets called, once the server has responded.
  #
  callApi: (path, callback, options={}) ->
    request @generateRequestOptions(path, options), (err, response, body) ->
      if err
        callback(err, null)
      else
        callback(null, JSON.parse(body))

  #
  # readProjects - Return the projects of the gitlab server to the passed callback.
  #
  # Parameters:
  # - callback: A function that gets called, once the result is in place.
  #
  readProjects: (callback) ->
    @callApi '/api/v3/projects', (err, projects) ->
      projects &&= projects.map (project) ->
        new Project project
      callback err, projects

  #
  # readMergeRequestPageFor - Returns a page slice of merge requests for a project.
  #
  # Parameters:
  # - project: A project, read via readProjects.
  # - page: The page that you want to get.
  # - callback: A function that gets called, once the result is in place.
  #
  readMergeRequestPageFor: (project, page, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @callApi "/api/v3/projects/#{project.id}/merge_requests?page=#{page}", (err, requests) ->
      requests &&= requests.map (request) ->
        new MergeRequest request
      callback err, requests

  #
  # readMergeRequestsFor - Returns merge requests for a project.
  #
  # Parameters:
  # - project: A project, read via readProjects.
  # - callback: A function that gets called, once the result is in place.
  #
  readMergeRequestsFor: (project, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    mergeRequests = []
    page          = 1
    self          = this

    _callback = (err, requests) ->
      if (err)
        callback(err, null)
      else if requests.length == 0
        callback(null, mergeRequests)
      else if page == 100
        callback(new Error('Just iterated to page 100 ... Something is strange!'))
      else
        page += 1
        mergeRequests = mergeRequests.concat requests
        self.readMergeRequestPageFor project, page, _callback

    @readMergeRequestPageFor project, page, _callback

  #
  # readMergeRequest - Returns a specific merge request.
  #
  # Parameters:
  # - project: An instance of Project
  # - id: An id of a merge request
  # - callback: A function that gets called, once the result is in place.
  #
  readMergeRequest: (project, id, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @callApi "/api/v3/projects/#{project.id}/merge_request/#{id}", (err, request) ->
      if request &&= new MergeRequest(request)
        callback null, request
      else
        err ||= new Error("Unable to find merge request ##{id} for project '#{project.displayName}'.")
        callback err, null

  readMergeRequestViaPublicId: (project, publicId, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @readMergeRequestsFor project, (err, mergeRequests) =>
      matchingRequests = mergeRequests.filter (mergeRequest) ->
        parseInt(mergeRequest.publicId, 10) == parseInt(publicId, 10)

      if matchingRequests.length == 0
        err ||= new Error("Unable to find merge request ##{publicId} for project '#{project.displayName}'.")
      else if matchingRequests.length > 1
        err ||= new Error('Too many merge requests found.')

      if err
        callback err, null
      else
        callback null, matchingRequests[0]

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
    @readProjects (err, projects) =>
      if err
        callback(err, null)
      else
        async.map(
          projects,
          (project, callback) =>
            @readMergeRequestsFor project, (err, requests) ->
              callback(err, { project: project, requests: requests })
          callback
        )

  #
  # searchProject - Returns a project that matches the passed needle.
  #
  # Parameters:
  # - needle: A string that gets searched for in the project names.
  # - callback: A function that gets called, once the result is in place.
  #
  searchProject: (needle, callback) ->
    @readProjects (err, projects) =>
      if err
        callback(err, null)
      else
        projects = projects.filter (project) ->
          project.hasName(needle)

        if projects.length == 0
          callback new Error("Unable to find a project that matches '#{needle}'."), null
        else if projects.length > 1
          callback new Error("Multiple projects have been found for '#{needle}'."), null
        else
          callback null, projects[0]

  readGroup: (groupId, callback) ->
    @callApi "/api/v3/groups/#{groupId}", (err, group) ->
      if group &&= new Group(group)
        callback null, group
      else
        err ||= new Error('No group found')
        callback err, null

  readGroupMembers: (group, callback) ->
    unless group instanceof Group
      throw new Error('The passed argument is no instance of Group.')

    @callApi "/api/v3/groups/#{group.id}/members", (err, members) ->
      if err
        callback err, null
      else
        members &&= members.map (member) -> new User(member)
        callback null, members

  readProjectMembers: (project, callback) ->
    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    @callApi "/api/v3/projects/#{project.id}/members", (err, members) ->
      if err
        callback err, null
      else if members.length == 0
        callback new Error("No members found for project '#{project.displayName}'"), null
      else
        members &&= members.map (member) -> new User(member)
        callback null, members

  assignMergeRequestTo: (member, project, mergeRequest, callback) ->
    unless member instanceof User
      throw new Error('The passed argument is no instance of User.')

    unless project instanceof Project
      throw new Error('The passed argument is no instance of Project.')

    unless mergeRequest instanceof MergeRequest
      throw new Error('The passed argument is no instance of MergeRequest.')

    url       = "/api/v3/projects/#{project.id}/merge_request/#{mergeRequest.id}?assignee_id=#{member.id}"
    _callback = (err, mergeRequest) ->
      if err
        callback err, null
      else
        mergeRequest &&= new MergeRequest(mergeRequest)
        callback null, mergeRequest

    @callApi url, _callback, method: 'PUT'

  #
  # assignMergeRequest - Assigns a merge request to a random project member.
  #
  # Parameters:
  # - projectName: A needle that will be used for searching the relevant projects.
  # - mergeRequestId: An ID of a merge request.
  # - callback: A function that gets called, once the result is in place.
  #
  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    @searchProject projectName, (err, project) =>
      if err
        callback err, null
      else
        @readMergeRequestViaPublicId project, mergeRequestId, (err, mergeRequest) =>
          if err
            callback err, null
          else if !mergeRequest.isOpen
            callback new Error("The merge request is already #{mergeRequest.state}!"), null
          else
            @readGroup project.ownerId, (err, group) =>
              if err
                callback err, null
              else
                @readGroupMembers group, (err, groupMembers) =>
                  if err
                    callback err, null
                  else
                    @readProjectMembers project, (err, projectMembers) =>
                      if err
                        callback err, null
                      else
                        members = groupMembers.concat projectMembers
                        members = _.uniq members, (user) -> user.id
                        member  = _.sample(members)

                        @assignMergeRequestTo member, project, mergeRequest, (err, mergeRequest) =>
                          if err
                            callback err, null
                          else
                            callback null, mergeRequest
