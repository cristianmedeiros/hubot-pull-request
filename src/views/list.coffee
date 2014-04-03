path    = require 'path'
_       = require 'lodash'
_s      = require 'underscore.string'

module.exports =
  render: (endpoint, scope, callback) ->
    endpoint.readMergeRequests (err, requests) ->
      if err
        callback err, null
      else
        answer = ""

        unless _.contains [null, '', '*'], scope
          requests = requests.filter (request) ->
            _s.startsWith request.state.toLowerCase(), scope.toLowerCase()

        if requests.length == 0
          callback null, "Nothing to do!"
        else
          groups = _.groupBy requests, (request) ->
            request.project.displayName

          Object.keys(groups).forEach (projectName) ->
            answer += "\n\n#{projectName}"
            answer += "\n#{[1..projectName.length].map(-> '-').join('')}"

            _.sortBy(groups[projectName], 'publicId').forEach (request) ->
              answer += "\n#{request.condensed}"

        callback null, "/quote #{answer.trim()}"
