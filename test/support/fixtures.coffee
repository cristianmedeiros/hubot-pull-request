_ = require 'lodash'

fixtures = module.exports =
  gitlab:
    project: (options) ->
      _.defaults options || {}, {
        id: 1
        path_with_namespace: 'company/project-1'
        namespace:
          id: 1
      }

    mergeRequest: (options) ->
      result = _.extend {
        id: 1
        state: 'opened'
        title: 'this merge request makes things better'
      }, options || {}
      result.iid ||= 10 + result.id
      result

  github:
    project: (options) ->
      _.defaults options || {}, {
        id: 1
        full_name: 'company/project-1'
        owner:
          id: 1
          type: 'User'
      }

    pullRequest: (options) ->
      result = _.extend {
        id: 1
        state: 'opened'
        title: 'this merge request makes things better'
      }, options || {}
      result.number ||= 10 + result.id
      result

    user: (options) ->
      _.defaults options || {},
        login: 'sdepold'
        id: 79163
        avatar_url: 'https://avatars.githubusercontent.com/u/79163?'
        gravatar_id: 'f30479a06db175157387334e03766420'
        url: 'https://api.github.com/users/sdepold'
        html_url: 'https://github.com/sdepold'
        followers_url: 'https://api.github.com/users/sdepold/followers'
        following_url: 'https://api.github.com/users/sdepold/following{/other_user}'
        gists_url: 'https://api.github.com/users/sdepold/gists{/gist_id}'
        starred_url: 'https://api.github.com/users/sdepold/starred{/owner}{/repo}'
        subscriptions_url: 'https://api.github.com/users/sdepold/subscriptions'
        organizations_url: 'https://api.github.com/users/sdepold/orgs'
        repos_url: 'https://api.github.com/users/sdepold/repos'
        events_url: 'https://api.github.com/users/sdepold/events{/privacy}'
        received_events_url: 'https://api.github.com/users/sdepold/received_events'
        type: 'User'
        site_admin: false
