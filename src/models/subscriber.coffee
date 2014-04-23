path    = require 'path'
_       = require 'lodash'
async   = require 'async'
User    = require path.resolve __dirname, '..', 'models', 'user'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports = class Subscriber
  constructor: (@robot, data) ->
    @service     = data.service
    @project     = data.project
    @user        = data.user
    @userId      = null
    @endpoint    = if @service == "gitlab" then helpers.gitlabEndpoint else helpers.githubEndpoint
    @subscribers = @robot.brain.data.subscribers

  initBrain: ->
    @subscribers ||= {}
    @subscribers[@service] ||= {}
    @subscribers[@service][@project] ||= []

  subscribed: ->
    !! @subscribers[@service] && !! @subscribers[@service][@project] && !! _.indexOf(@subscribers[@service][@project], @user) >= 0

  save: (callback) ->
    async.waterfall [
      (asyncCallback) =>
        @endpoint._searchProject @project, (err, project) =>
          return asyncCallback(err, null) if err
          asyncCallback null, project

      (project, asyncCallback) =>
        @endpoint._readCollaborators project, (err, collaborators) =>
          return asyncCallback(err, null) if err
          asyncCallback null, collaborators

      (collaborators, asyncCallback) =>
        # users = collaborators.map (c) -> new User(c)
        # userNames = users.map (u) -> u.username

        userNames = collaborators.map (c) -> c.username

        if !! userNames[@user]
          return asyncCallback(new Error("User #{@user} is not a valid collaborator for #{@service} project #{@project}!"), null)
        else if @subscribed()
          return asyncCallback(new Error("User #{@user} is already subscribed to project #{@project}."), null)
        else
          @initBrain()
          @subscribers[@service][@project].push(@user)
          @robot.brain.emit 'save'
          asyncCallback(null, @user)
    ], callback

  remove: ->
    if @subscribed()
      _.pull(@subscribers[@service][@project], @user)
      @robot.brain.emit 'save'
      true
    else
      "User #{@user} was not subscribed to project #{@project}."

  # Retrieves an array of usernames, subscribed to the given service & project.
  @findNamesFor: (robot, service, project) ->
    subscribers = robot.brain.data.subscribers
    if !! subscribers[service] && !! subscribers[service][project] && subscribers[service][project].length > 0
      subscribers[service][project]
    else
      null
