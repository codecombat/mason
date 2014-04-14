rmdir = require 'rimraf'
config = require './config'
async = require 'async'
exec = require('child_process').exec
colors = require 'colors'
sedCommand = "sed"
if require('os').platform() is 'darwin' then sedCommand = "gsed"

execCommandInApplicationCodeDirectory = (command, cb) ->
  exec command, cwd: config.localRepositoryFolder, (err, stdout, stderr) ->
    if err?
      console.log stderr
      return cb err
    cb null

prepareDeploymentFiles = (cb) ->
  async.waterfall [
    removeOldApplicationCode
    cloneGitHubRepository
    installNodeModules
    installNewRelic
    bowerInstall
    brunch
    removeCompressed
    compress
  ], (err) ->
    if err? then return cb err
    console.log "Deployment files prepared!".green
    cb null

removeOldApplicationCode = (cb) -> rmdir config.localRepositoryFolder, cb

cloneGitHubRepository = (cb) ->
  cloneCommand = "git clone -b #{config.productionGitBranchName} #{config.productionRepositoryGitLocation} #{config.localRepositoryFolder + "/"}"
  process.stdout.write "Cloning GitHub repository... "
  exec cloneCommand, (err, stdout, stderr) ->
    if err?
      console.log stderr
      return cb err
    console.log "✔".green
    cb null

installNodeModules = (cb) ->
  process.stdout.write "Installing node modules... "
  execCommandInApplicationCodeDirectory "npm install", (err) ->
    console.log "✔".green
    cb err
  
installNewRelic = (cb) ->
  process.stdout.write "Installing New Relic... "
  prependNewRelicRequire = (cb) -> execCommandInApplicationCodeDirectory sedCommand + ' -i "1i require(\'newrelic\')\n" server.coffee', cb

  installNewRelicNodeModule = (cb) -> execCommandInApplicationCodeDirectory "npm install newrelic", cb

  copyNewRelicJSFile = (cb) ->  execCommandInApplicationCodeDirectory "cp node_modules/newrelic/newrelic.js ./", cb

  replaceNewRelicKeys = (cb) ->
    command = "#{sedCommand} -i 's/license key here/#{config.newRelicLicenseKey}/g' newrelic.js"
    execCommandInApplicationCodeDirectory command, cb

  setNewRelicLogLevel = (cb) -> execCommandInApplicationCodeDirectory "#{sedCommand} -i 's/trace/warn/g' newrelic.js", cb

  replaceNewRelicAppName = (cb) ->
    execCommandInApplicationCodeDirectory "#{sedCommand} -i 's/My Application/#{config.newRelicApplicationName}/g' newrelic.js", cb
  async.waterfall [
    prependNewRelicRequire
    installNewRelicNodeModule
    copyNewRelicJSFile
    replaceNewRelicKeys
    setNewRelicLogLevel
    replaceNewRelicAppName
  ], (err) ->
    console.log "✔".green
    cb err

bowerInstall = (cb) -> 
  process.stdout.write "Installing bower dependencies... "
  execCommandInApplicationCodeDirectory "./node_modules/.bin/bower install", (err) ->
    console.log "✔".green
    cb err

brunch = (cb) -> 
  process.stdout.write "Brunching... "
  execCommandInApplicationCodeDirectory "./node_modules/.bin/brunch build --production", (err) ->
    console.log "✔".green
    cb err
    
removeCompressed = (cb) -> exec "rm -rf #{config.applicationTarName}", (err, stdout, stderr) ->
  if err?
    console.log stderr
    return cb err
  cb null

compress = (cb) -> 
  process.stdout.write "Compressing... "
  exec "tar czf #{config.applicationTarName} #{config.localRepositoryFolder}", (err, stdout, stderr) ->
    if err?
      console.log stderr
      return cb err
    console.log "✔".green
    cb null

module.exports.prepareDeploymentFiles = prepareDeploymentFiles
