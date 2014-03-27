# Description:
#   Interacts with merge / pull requests of Gitlab and Github.
#
# Commands:
#   hubot merge-request list - Returns a list of all open merge/pull requests.
#   hubot mr list            - Returns a list of all open merge/pull requests.
#   hubot pull-request list  - Returns a list of all open merge/pull requests.
#   hubot pr list            - Returns a list of all open merge/pull requests.

path    = require 'path'
helpers = require path.resolve(__dirname, '..', 'helpers')

module.exports = (robot) ->
  robot.respond /((m(erge-)?r(equest)?)|(p(ull-)?r(equest)?))\slist/, (msg) ->
    helpers.mergeRequests.read (err, requests) ->
      if err
        msg.reply "An error occurred: #{err}"
      else
        msg.reply "omnom"
