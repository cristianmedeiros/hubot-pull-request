# Description:
#   Handle a user's subscriptions to Hubot pull request assignments.
#
# Commands:
#   hubot github s(ubscribe) <project-name> <identifier>        - Subscribe a Github user to receive pull requests to a certain project from Hubot.
#   hubot gitlab s(ubscribe) <project-name> <identifier>        - Subscribe a Gitlab user to receive pull requests to a certain project from Hubot.
#   hubot github uns(ubscribe) <project-name> <identifier>      - Unsubscribe a Github user from receiving pull requests to a certain project from Hubot.
#   hubot gitlab uns(ubscribe) <project-name> <identifier>      - Unsubscribe a Gitlab user from receiving pull requests to a certain project from Hubot.
#   hubot github subscribers <project-name>?                    - List all users subscribed to pull requests via Hubot for a certain Github project.
#   hubot gitlab subscribers <project-name>?                    - List all users subscribed to pull requests via Hubot for a certain Gitlab project.
#

path       = require 'path'
_          = require 'lodash'
helpers    = require path.resolve(__dirname, '..', 'helpers')
Subscriber = require path.resolve(__dirname, '..', 'models', 'subscriber')
Util       = require "util"

module.exports = (robot) ->
  subscribeRegExp = /(github|gitlab)\s(s(ubscribe)?)(\s[^\s]+){2}/
  unsubscribeRegExp = /(github|gitlab)\s(uns(ubscribe)?)(\s[^\s]+){2}/
  listRegExp = /(github|gitlab)\s(subscribers)(\s[^\s]+){0,2}/

  # Parse service, project and user from command
  splitCommand = (msg, regExp) ->
    service = null
    project = null
    user = null

    command   = msg.replace(/(^[^\s]+\s)/, "")
    service   = command.match(/[^\s]+/)[0]
    otherArgs = command.replace(/([^\s]+)\s([^\s]+)(\s)?/, "")
    argsMatch = otherArgs.match(/[^\s]+/g)
    if !! argsMatch
      project   = argsMatch[0] if argsMatch.length >= 1
      user      = argsMatch[1] if argsMatch.length >= 2
    
    { service: service, project: project, user: user }

  # Subscribe a user to a project
  robot.respond subscribeRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, subscribeRegExp)

    subscriber = new Subscriber(robot, params)
    subscriber.save (err, user) ->
      if err
        msg.reply "An error occured:\n#{err}"
      else
        msg.send "Subscribed #{params.service} user #{params.user} to pull requests for #{params.project}!"
    
    # result = subscriber.save()
    # if result == true
    #   msg.send "Subscribed #{params.service} user #{params.user} to pull requests for #{params.project}!"
    # else if typeof result == "string"
    #   msg.reply "An error occured:\n#{result}"
    # else
    #   msg.reply "An error occured:\nCould not subscribe user!"

  # Unsubscribe a user from a project
  robot.respond unsubscribeRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, unsubscribeRegExp)

    subscriber = new Subscriber(robot, params)
    result = subscriber.remove()
    if result == true
      msg.send "#{params.service} subscriber #{params.user} removed from project #{params.project}!"
    else if typeof result == "string"
      msg.reply "An error occured:\n#{result}"
    else
      msg.reply "An error occured:\nCould not unsubscribe user!"

  # List subscribed users
  robot.respond listRegExp, (msg) ->
    params = splitCommand(msg.envelope.message.text, listRegExp)
    subscribers = robot.brain.data.subscribers
    if !! params.service
      if _.has(subscribers, params.service)
        subscribers = subscribers[params.service]
      else
        msg.send "No subscribers found for #{params.service}."
        return
    if !! params.project
      if _.has(subscribers, params.project)
        subscribers = subscribers[params.project]
      else
        msg.send "No subscribers found for #{params.service} project #{params.project}."
        return

    msg.send Util.inspect(subscribers, false, 4)
    