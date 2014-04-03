path    = require 'path'
_s      = require 'underscore.string'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports =
  render: (scope, callback) ->
    helpers.gitlabEndpoint.readMergeRequests (err, requests) ->
      if err
        callback err, null
      else
        answer = ""

        if scope == '*'
          scope = ''
        else
          scope ||= 'open'

        if scope != ''
          requests = requests.filter (request) ->
            _s.startsWith(request.state.toLowerCase(), scope.toLowerCase())

        if requests.length > 0
          projectName = requests[0].project.displayName

          answer += "\n\n#{projectName}"
          answer += "\n#{[1..projectName.length].map(-> '-').join('')}"

          requests.forEach (request) ->
            answer += "\n#{request.condensed}"

        callback null, "/quote #{answer.trim()}"
