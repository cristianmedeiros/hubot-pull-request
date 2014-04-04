path    = require 'path'
_       = require 'lodash'
_s      = require 'underscore.string'

module.exports =
  render: (msg, endpoint, scope) ->
    requestType = if endpoint.name == 'github'
      'pull requests'
    else
      'merge requests'

    msg.reply "Searching for #{requestType} on #{endpoint.name} ..."

    endpoint.readMergeRequests (err, requests) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        answer = ""

        unless _.contains [null, '', '*'], scope
          requests = requests.filter (request) ->
            _s.startsWith request.state.toLowerCase(), scope.toLowerCase()

        if requests.length == 0
          msg.send "Nothing to do!"
        else
          groups = _.groupBy requests, (request) ->
            request.project.displayName

          Object.keys(groups).forEach (projectName) ->
            answer += "\n\n#{projectName}"
            answer += "\n#{[1..projectName.length].map(-> '-').join('')}"

            _.sortBy(groups[projectName], 'publicId').forEach (request) ->
              answer += "\n#{request.condensed}"

          msg.send "/quote #{answer.trim()}"
