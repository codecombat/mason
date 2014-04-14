async = require 'async'
yesno = require 'yesno'
config = require './config'
needle = require 'needle'
RemoteHandler = require './remote'
localFilePreparer = require './localFilePreparer'
ec2 = require './ec2'
configurator = require './configurator'
_ = require 'lodash'

clearCloudflareCache = (cb) ->
  cloudflareAPIURL = "https://www.cloudflare.com/api_json.html"
  requestData = 
    'a':'fpurge_ts'
    'tkn': config.cloudflareToken
    'email':config.cloudflareEmail
    'z': config.cloudflareDomain
    'v':1 
  needle.post cloudflareAPIURL, requestData, (err, resp, body) -> cb err
    
  
deploymentCode = ->
  localFilePreparer.prepareDeploymentFiles (err) ->
    if err? then return console.log err
    ec2.spinUpNServers 1, (err, servers) ->
      if err? then return console.log err
      async.each servers, configurator.configureServer, (err) ->
        if err? then return console.log err
        configurator.getIP servers[0], (err, IP) ->
          if err? then return console.log err
          yesno.ask "Are the servers working?(visit http://#{IP}:3000)",false, (ok) ->
            if ok
              serverInstanceIDs = _.pluck servers, "InstanceId"
              serverObjects = []
              for instanceId in serverInstanceIDs
                serverObjects.push({"InstanceId":instanceId})
              ec2.getInstancesOnLoadBalancer (err, oldInstances) ->
                if err? then return console.log err

                ec2.swapInstancesFromLoadBalancer oldInstances, serverObjects, (err) ->
                  if err? then return console.log err
                  console.log "Clearning the CloudFlare cache..."
                  clearCloudflareCache (err) ->
                    if err? then console.log err
                    console.log "Waiting 5 minutes to destroy the instances(ELB connection drain 300 seconds)"
                    console.log "Send SIGINT (Ctrl-C) to immediately kill the servers"
                    killInstances = (cb) ->
                      instanceIDs = _.pluck oldInstances, "InstanceId"
                      killParams =
                        InstanceIds: instanceIDs
                      ec2.terminateInstances killParams, (err, data) ->
                        if err? then return cb err
                        console.log "Terminated instances!"
                        cb null
                    sendSIGINTToSelf = ->
                      process.kill(process.pid, "SIGINT")
  
                    _.delay sendSIGINTToSelf, 300 * 1000
                    process.on "SIGINT", ->
                      killInstances (err) ->
                        if err? then return console.log err
                        process.exit()
            else
              console.log "Aborted! You must manually destroy the servers now."

deploymentCode()
