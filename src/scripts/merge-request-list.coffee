# Description:
#   Lists merge / pull requests of Gitlab and Github.
#
# Commands:
#   hubot merge-request list <scope> - Returns a list of all merge/pull requests.
#   hubot mr list <scope>            - Returns a list of all merge/pull requests.
#   hubot pull-request list  <scope> - Returns a list of all merge/pull requests.
#   hubot pr list <scope>            - Returns a list of all merge/pull requests.
#
# Scopes:
#   open:   All open merge requests. This is the default.
#   closed: All closed merge requests.
#   merged: All accepted / merged merge requests.
#   *:      All merge requests
#

path = require 'path'
view = require path.resolve(__dirname, '..', 'views', 'merge-request-list')

module.exports = (robot) ->
  routeRegExp = /((m(erge-)?r(equest)?)|(p(ull-)?r(equest)?))\slist/

  robot.respond routeRegExp, (msg) ->
    scope = msg.envelope.message.text.replace(/(^bender )/, "").replace(routeRegExp, "").trim()

    msg.reply "Search for merge requests ..."

    view.render scope, (err, content) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        msg.send content
