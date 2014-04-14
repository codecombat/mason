Connection = require 'ssh2'
remoteUsername = "ubuntu"
colors = require 'colors'
String.prototype.repeat = (times) -> (new Array(times + 1)).join(@)

class RemoteHandler
  constructor: (@ip, @privateKeyPath, cb) ->
    process.stdout.write "Connecting to #{@ip}... "
    @c = new Connection()
    @setupListeners(cb)
    @connect()
    
  setupListeners: (cb) ->
    @c.on 'ready', -> 
      console.log "✔".green
      cb null
    @c.on 'error', (err) ->
      console.log "SSH connection error: #{err}"
      cb err
      
  connect: ->
    @c.connect
      host: @ip
      port: 22
      username: remoteUsername
      privateKey: require('fs').readFileSync(@privateKeyPath)
  
  exec: (command, cb) ->
    @c.exec command, (err, stream) =>
      if err? then return cb err
      stream.on 'data', (data, extended) =>
        if extended is "stderr" then return else console.log "===SSH STDOUT===".rainbow
        process.stdout.write(''+data)
        console.log "================".rainbow
      stream.on 'exit', (code, signal) -> cb null
  
  transferFile: (origin,destination,cb) ->
    @c.sftp (err, sftp) =>
      if err? then return cb err
      sftp.fastPut origin, destination, step: @transferProgressDisplay, (err) ->
        sftp.end()
        console.log " "
        cb err
  transferProgressDisplay: (totalTransferred,chunk,total) -> 
    fractionDone = totalTransferred/total
    process.stdout.write "File upload progress: ["
    totalWidth = 50
    numberOfBars = Math.floor(50 * fractionDone)
    process.stdout.write "#{"=".repeat(numberOfBars)}>#{" ".repeat(totalWidth-numberOfBars)}".rainbow
    process.stdout.write "] \r"
  end: -> @c.end()
  
module.exports = RemoteHandler 