fs   = require 'fs'
path = require 'path'

module.exports = (robot, scripts) ->
  routesPath  = path.resolve(__dirname, 'src', 'routes')
  helpersPath = path.resolve(__dirname, 'src', 'helpers')
  helpers     = require helpersPath

  helpers.checkConfigs()

  fs.exists routesPath, (exists) ->
    if exists
      for script in fs.readdirSync(routesPath)
        if scripts? and '*' not in scripts
          robot.loadFile(routesPath, script) if script in scripts
        else
          robot.loadFile(routesPath, script)
