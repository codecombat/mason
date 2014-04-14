module.exports = 
  loadBalancerName: "CoCoLoadBalancer"
  applicationServerNamePrefix: "Application Instance #"
  applicationKeyPath: "some/key.ext"
  remoteTarPath: "/some/path/here"
  applicationTarName: "codecombat.tar.gz"
  awsCredentialsFilePath: "./credentials.json"
  environmentVariablesFilePath: "./EnvironmentVariables.txt"
  remoteStartCommand: "forever start codecombat/index.js"
  productionGitBranchName: "production"
  productionRepositoryGitLocation: "git@github.com:codecombat/codecombat.git"
  localRepositoryFolder: "codecombat"
  newRelicLicenseKey: "lololololol"
  newRelicApplicationName: "My super-cool application"
  cloudflareEmail: "hello@goodbye.com"
  cloudflareDomain: "codecombat.com"
  cloudflareToken: "asdfasdfawefasdfadsfasdadsf"
  papertrailPort: 9001
  applicationServerConfiguration:
    ImageId: "ami-d051208fj2"
    InstanceType: "m3.medium"
    MinCount: 1
    MaxCount: 1
    SecurityGroups: ["Some security group"]
    KeyName: "MyKeyName"
    Placement:
      AvailabilityZone: "us-west-1c"