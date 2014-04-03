# Description:
#   Lists merge / pull requests of Gitlab and Github.
#
# Commands:
#   hubot merge-request l(ist) <scope> - Returns a list of all merge/pull requests.
#   hubot mr l(ist) <scope>            - Returns a list of all merge/pull requests.
#   hubot pull-request l(ist)  <scope> - Returns a list of all merge/pull requests.
#   hubot pr l(ist) <scope>            - Returns a list of all merge/pull requests.
#
# Scopes:
#   open:   All open merge requests. This is the default.
#   closed: All closed merge requests.
#   merged: All accepted / merged merge requests.
#   *:      All merge requests
#

path    = require 'path'
view    = require path.resolve(__dirname, '..', 'views', 'list')
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports = (robot) ->
  routeRegExp = /((merge-request|mr)|(pull-request|pr))\sl(ist)?/

  robot.respond routeRegExp, (msg) ->
    scope    = msg.envelope.message.text.replace(/(^bender )/, "").replace(routeRegExp, "").trim()
    endpoint = if !!msg.envelope.message.text.match(/(pull-request|pr)\s/)
      helpers.githubEndpoint
    else
      helpers.gitlabEndpoint

    if scope == '*'
      scope = ''
    else
      scope ||= 'open'

    msg.reply "Searching for merge requests ..."

    view.render endpoint, scope, (err, content) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        msg.send content
