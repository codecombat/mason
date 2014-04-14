async = require 'async'
colors = require 'colors'
config = require './config'
_ = require 'lodash'
AWS = require 'aws-sdk'
AWS.config.loadFromPath(config.awsCredentialsFilePath)
ec2 = new AWS.EC2()
elb = new AWS.ELB()

spinUpNewServer = (cb) ->
  async.waterfall [
    createNewAppInstance
    nameApplicationServer
    waitForInstanceInitialization
  ] , cb

createNewAppInstance = (cb) ->
  ec2.runInstances config.applicationServerConfiguration, (err, data) ->
    if err? then return cb(err, null)
    instance = data.Instances[0]
    cb null, instance

nameApplicationServer = (instance, cb) ->
  name =  config.applicationServerNamePrefix + "#{Math.floor((Math.random()*10000)+1)}"
  tagParameters =
    Resources: [instance.InstanceId]
    Tags: [ { Key: "Name", Value: name } ]
  process.stdout.write "Naming instance #{instance.InstanceId} \"#{name}\"... "
  ec2.createTags tagParameters, (err) ->
    if err? then cb err
    console.log "✔".green
    cb null, instance

waitForInstanceInitialization = (instance, cb) ->
  waiterParameters =
    InstanceIds: [instance.InstanceId]
  process.stdout.write "Waiting for instance #{instance.InstanceId} to start... "
  ec2.waitFor 'instanceRunning', waiterParameters, (err) ->
    if err then return cb err
    console.log "✔".green
    process.stdout.write "Waiting for SSH daemon to start... "
    #TODO: Make it just retry instead of wait
    callback = (cb, instance) ->
      console.log "✔".green
      cb null, instance
    _.delay callback, 30000, cb, instance

getInstancesOnLoadBalancer = (cb) ->
  loadBalancerRequestParameters = 
    LoadBalancerNames: [config.loadBalancerName]
  elb.describeLoadBalancers loadBalancerRequestParameters, (err, data) ->
    if err? then return cb err
    cb null, data.LoadBalancerDescriptions[0].Instances
    
spinUpNServers = (n, cb) ->
  async.times n, (n, next) ->
    spinUpNewServer next
  , cb
    
swapInstancesFromLoadBalancer = (oldInstances, newInstances, cb) ->
  params = 
    Instances: newInstances
    LoadBalancerName: config.loadBalancerName
    
  elb.registerInstancesWithLoadBalancer params, (err, data) ->
    if err? then return cb err
    testInstanceID = data.Instances[0].InstanceId
    instanceHealth = null
    console.log "Waiting until new instances are in service!"
    instanceHealthCheck = (cb) ->
      healthCheckParams = 
        LoadBalancerName: config.loadBalancerName
        Instances: [InstanceId: testInstanceID]
      elb.describeInstanceHealth healthCheckParams, (err, data) ->
        instanceHealth = data.InstanceStates[0].State
        cb err
    instanceHealthTest = -> instanceHealth isnt "InService"
      
    async.doWhilst instanceHealthCheck,instanceHealthTest, (err) ->
      if err then return cb err
      console.log "Deregistering old instances..."
      degregistrationParameters = 
        Instances: oldInstances
        LoadBalancerName: config.loadBalancerName
      elb.deregisterInstancesFromLoadBalancer degregistrationParameters, (err, data) ->
        if err? then return cb err
        console.log "Old instances deregistered!"
        cb null

terminateInstances = (parameters, cb) ->
  ec2.terminateInstances parameters, cb
       
module.exports.spinUpNewServer = spinUpNewServer 
module.exports.spinUpNServers = spinUpNServers
module.exports.getInstancesOnLoadBalancer = getInstancesOnLoadBalancer
module.exports.swapInstancesFromLoadBalancer = swapInstancesFromLoadBalancer
module.exports.terminateInstances = terminateInstances