# Description:
#   Interacts with merge / pull requests of Gitlab and Github.
#
# Commands:
#   hubot merge-request a(ssign) <project-name> <identifier> - Assigns a merge request to a company member.
#   hubot mr a(ssign) <project-name> <identifier>            - Assigns a merge request to a company member.
#   hubot pull-request a(ssign)  <project-name> <identifier> - Assigns a merge request to a company member.
#   hubot pr a(ssign) <project-name> <identifier>            - Assigns a merge request to a company member.
#
# Scopes:
#   open:   All open merge requests. This is the default.
#   closed: All closed merge requests.
#   merged: All accepted / merged merge requests.
#   *:      All merge requests
#

path       = require 'path'
_s         = require 'underscore.string'
view       = require path.resolve(__dirname, '..', 'views', 'assign')
helpers    = require path.resolve(__dirname, '..', 'helpers')
Subscriber = require path.resolve(__dirname, '..', 'models', 'subscriber')

module.exports = (robot) ->
  routeRegExp = /((m(erge-)?r(equest)?)|(p(ull-)?r(equest)?))\sa(ssign)?/

  robot.respond routeRegExp, (msg) ->
    botNameRemoval = /(^[^\s]+\s+)/
    message        = msg.envelope.message.text.replace(botNameRemoval, "").replace(routeRegExp, "").trim()
    match          = message.match(/([^\s]+)\s#?([\d]+)/)
    projectName    = match[1]
    mergeRequestId = match[2]
    endpoint       = if !!msg.envelope.message.text.match(/(pull-request|pr)\s/)
      helpers.githubEndpoint
    else
      helpers.gitlabEndpoint

    # Retrieve the subscribed user pool for the current endpoint & project (if any)
    serviceName = endpoint.name
    currentServiceUser = msg.message.user[serviceName]
    userNames = Subscriber.findNamesFor(robot, serviceName, projectName, currentServiceUser)

    view.render msg, endpoint, projectName, mergeRequestId, userNames
