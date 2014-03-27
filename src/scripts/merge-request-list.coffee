# Description:
#   Interacts with merge / pull requests of Gitlab and Github.
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

path    = require 'path'
helpers = require path.resolve(__dirname, '..', 'helpers')
_s      = require 'underscore.string'

module.exports = (robot) ->
  routeRegExp = /((m(erge-)?r(equest)?)|(p(ull-)?r(equest)?))\slist/

  robot.respond routeRegExp, (msg) ->
    scope = msg.envelope.message.text.replace(/(^bender )/, "").replace(routeRegExp, "").trim()

    helpers.gitlab.readMergeRequests (err, result) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        answer = ""

        result.forEach (hash) ->
          requests = hash.requests

          if scope == '*'
            scope = ''
          else
            scope ||= 'open'

          if scope != ''
            requests = requests.filter (request) ->
              _s.startsWith(request.state.toLowerCase(), scope.toLowerCase())

          if requests.length > 0
            answer += "\n\n- #{hash.project.name}"

            requests.forEach (request) ->
              answer += "\n    ##{request.id} #{request.state.toUpperCase()} #{request.title}"

        msg.send answer
