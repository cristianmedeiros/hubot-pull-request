path    = require 'path'
_s      = require 'underscore.string'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports =
  render: (projectName, mergeRequestId, callback) ->
    helpers.gitlab.assignMergeRequest projectName, mergeRequestId, (err, mergeRequest) ->
      if err
        callback err, null
      else
        callback null, "Successfully assigned the merge request '#{mergeRequest.title}' to #{mergeRequest.displayAssignee}."
