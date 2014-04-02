methodMissing = (methodName) ->
  throw new Error("The method '#{methodName}' is not implemented!")

module.exports =
  generateRequestOptions: (remotePath, otherOptions={}) ->
    methodMissing('generateRequestOptions')
  callApi: (path, callback, options={}) ->
    methodMissing('callApi')
  readProjects: (callback) ->
    methodMissing('readProjects')
  readMergeRequestPageFor: (project, page, callback) ->
    methodMissing('readMergeRequestPageFor')
  readMergeRequestsFor: (project, callback) ->
    methodMissing('readMergeRequestsFor')
  readMergeRequest: (project, id, callback) ->
    methodMissing('readMergeRequest')
  readMergeRequestViaPublicId: (project, publicId, callback) ->
    methodMissing('readMergeRequestViaPublicId')
  readMergeRequests: (callback) ->
    methodMissing('readMergeRequests')
  searchProject: (needle, callback) ->
    methodMissing('searchProject')
  readGroup: (groupId, callback) ->
    methodMissing('readGroup')
  readGroupMembers: (group, callback) ->
    methodMissing('readGroupMembers')
  readProjectMembers: (project, callback) ->
    methodMissing('readProjectMembers')
  assignMergeRequestTo: (member, project, mergeRequest, callback) ->
    methodMissing('assignMergeRequestTo')
  assignMergeRequest: (projectName, mergeRequestId, callback) ->
    methodMissing('assignMergeRequest')
