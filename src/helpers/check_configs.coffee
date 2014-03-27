module.exports = ->
  unless process.env.HUBOT_PULL_REQUESTS_CONFIG
    throw new Error("No hubot configuration in place. Please define the configuration as per the documentation of the hubot-pull-request plugin.")

