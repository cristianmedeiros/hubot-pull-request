path    = require 'path'
_s      = require 'underscore.string'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports =
  render: (msg, endpoint, projectName, mergeRequestId) ->
    requestType = if endpoint.name == 'github'
      'pull request'
    else
      'merge request'

    msg.reply "Assigning #{requestType} ##{mergeRequestId} of #{projectName} ..."

    endpoint.assignMergeRequest projectName, mergeRequestId, (err, mergeRequest) ->
      if err
        msg.reply "An error occurred:\n#{err}"
      else
        msg.send "Successfully assigned the merge request '#{mergeRequest.title}' to #{mergeRequest.displayAssignee}."
