methodMissing = (methodName) ->
  throw new Error("The method '#{methodName}' is not implemented!")

module.exports =
  readMergeRequests: (callback) ->
    methodMissing('readMergeRequests')
  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    methodMissing('assignMergeRequest')
