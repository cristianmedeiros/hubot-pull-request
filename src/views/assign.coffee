path    = require 'path'
_s      = require 'underscore.string'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports =
  render: (msg, endpoint, projectName, mergeRequestId) ->
    msg.reply "Assigning merge request ##{mergeRequestId} of #{projectName} ..."

    endpoint.assignMergeRequest projectName, mergeRequestId, (err, mergeRequest) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        msg.send "Successfully assigned the merge request '#{mergeRequest.title}' to #{mergeRequest.displayAssignee}."
