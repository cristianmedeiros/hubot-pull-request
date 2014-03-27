fs   = require 'fs'
path = require 'path'

module.exports = (robot, scripts) ->
  scriptsPath = path.resolve(__dirname, 'src', 'scripts')
  helpersPath = path.resolve(__dirname, 'src', 'helpers')
  helpers     = require helpersPath

  helpers.checkConfigs()

  fs.exists scriptsPath, (exists) ->
    if exists
      for script in fs.readdirSync(scriptsPath)
        if scripts? and '*' not in scripts
          robot.loadFile(scriptsPath, script) if script in scripts
        else
          robot.loadFile(scriptsPath, script)
