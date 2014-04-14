fs = require 'fs'
async = require 'async'
colors = require 'colors'
config = require './config'
RemoteHandler = require './remote'
AWS = require 'aws-sdk'
AWS.config.loadFromPath(config.awsCredentialsFilePath)
ec2 = new AWS.EC2()
environmentVariableString = fs.readFileSync(config.environmentVariablesFilePath).toString().replace(/(\r\n|\n|\r)/gm," ")

configureServer = (instance, cb) ->
  async.waterfall [
    getInstancePublicIPAddress.bind @, instance
    generateRemoteHandler
    transferApplicationTar
    untarRemoteTar
    startPapertrail
    startServer
  ], cb

getInstancePublicIPAddress = (instance, cb) ->
  ec2.describeInstances InstanceIds: [instance.InstanceId], (err, data) ->
    cb err, data?.Reservations?[0]?.Instances?[0]?.PublicIpAddress

generateRemoteHandler = (publicIP, cb) ->
  remoteHandler = new RemoteHandler publicIP, config.applicationKeyPath, (err) -> cb err, remoteHandler

transferApplicationTar = (remoteHandler, cb) ->
  remoteHandler.transferFile config.applicationTarName, config.remoteTarPath, (err) -> cb err, remoteHandler
    
untarRemoteTar = (remoteHandler, cb) ->
  process.stdout.write "Untarring remotely... "
  remoteHandler.exec "tar xzf #{config.applicationTarName}", (err) ->
    console.log "✔".green
    cb err, remoteHandler
    
startPapertrail = (remoteHandler, cb) ->
  process.stdout.write "Starting PaperTrail..."
  remoteHandler.exec "remote_syslog -p #{config.papertrailPort} \"/home/ubuntu/.forever/*.log\"", (err) ->
    console.log "✔".green
    cb err, remoteHandler

startServer = (remoteHandler, cb) ->
  console.log "Starting remote server... "
  remoteHandler.exec "#{environmentVariableString} #{config.remoteStartCommand}", (err) ->
    remoteHandler.end()
    console.log "✔".green
    cb err

module.exports.configureServer = configureServer 
module.exports.getIP = getInstancePublicIPAddress