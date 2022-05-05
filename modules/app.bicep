param location string
param imageNameAndTag string
param containerPort string
param acrName string
param appName string
param aspName string
param vnetIntegrationSubnetId string

// App Settings
param acrUseManagedIdentityCreds bool
param vnetRouteAllEnabled bool
param clientAffinityEnabled bool
param httpLogsEnabled bool
param httpLogsRetentionDays int
param httpLogsRetentionMb int
param serverEnvironment string

// var affix = substring(uniqueString(resourceGroup().id), 0, 6)
var containerImageName = 'DOCKER|${existingAcr.properties.loginServer}/${imageNameAndTag}'
// var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var appSettings = [
  {
    name: 'WEBSITES_PORT'
    value: containerPort
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
  {
    name: 'WEBSITE_LOCAL_CACHE_OPTION'
    value: 'Always'
  }
  {
    name: 'SERVER_ENVIRONMENT'
    value: serverEnvironment
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: listCredentials(existingAcr.id, '2021-09-01').passwords[0].value
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: existingAcr.properties.loginServer
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: acrName
  }
]

resource existingAcr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource asp 'Microsoft.Web/serverfarms@2021-02-01' = { // the date here is the api version, but what does different date stand for
  name: aspName
  location: location
  sku: {
    name: 'P1V3'
    tier: 'PremiumV3'
    size: 'P1V3'
    family: 'P'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource app 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true // Setting this value to false disables the app (takes app offline)
    serverFarmId: asp.id // Resource ID of the associated App Service Plan
    reserved: true
    isXenon: false // Obsolete: Hyper-V sandbox
    hyperV: false // Hyper-V sandbox
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: containerImageName // Linux App Framework and version
      acrUseManagedIdentityCreds: acrUseManagedIdentityCreds // Flag to use Managed Identity Creds for ACR pull
      alwaysOn: true 
      http20Enabled: false // configures a web site to allow clients to connect over http2.0
      functionAppScaleLimit: 0 // Max number of workers that a site can scale out to. This setting only applies to the Consumption and Elastic Premium Plans
      minimumElasticInstanceCount: 1 // Number of minimum instance count for a site. This setting only applies to the Elastic Plans
    }
    virtualNetworkSubnetId: vnetIntegrationSubnetId
    scmSiteAlsoStopped: false // true to stop SCM (KUDU) site when the app is stopped. The default is false
    clientAffinityEnabled: clientAffinityEnabled // true to enable client affinity; false to stop sending session affinity cookies, which route client requests in the same session to the same instance. Default is true
    clientCertEnabled: false // true to enable client certificate authentication (TLS mutual authentication)
    clientCertMode: 'Required' // ClientCertEnabled false means clientCert is ignored
    httpsOnly: false // accept only https requests
    keyVaultReferenceIdentity: 'SystemAssigned' // Identity to use for Key Vault Reference authentication
  }
  resource blueSlot 'slots' = {
    name: 'staging'
    location: location
    kind: 'app,linux,container'
    properties: {
      serverFarmId: asp.id
      siteConfig: {
        acrUseManagedIdentityCreds: true
        appSettings: appSettings
      }
    }
    identity: {
      type: 'SystemAssigned'
    }
  }
}

resource appConfig 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: app
  name: 'web'
  properties: {
    appSettings: appSettings
    numberOfWorkers: 1
    linuxFxVersion: containerImageName
    acrUseManagedIdentityCreds: acrUseManagedIdentityCreds
    logsDirectorySizeLimit: 35 // HTTP logs directory size limit
    detailedErrorLoggingEnabled: false 
    loadBalancing: 'LeastRequests'
    autoHealEnabled: false 
    vnetRouteAllEnabled: vnetRouteAllEnabled // Virtual Network Route All enabled. This causes all outbound traffic to have Virtual Network Security Groups and User Defined Routes applied
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2' // configures the minimum version of TLS required for SSL requests
    scmMinTlsVersion: '1.0' 
    ftpsState: 'AllAllowed'
  }
}

resource appConfigLog 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: app
  name: 'logs'
  properties: {
    httpLogs: {
      fileSystem: {
        enabled: httpLogsEnabled
        retentionInDays: httpLogsRetentionDays
        retentionInMb: httpLogsRetentionMb
      }
    }
  }
}

resource appConfigSlot 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'slotConfigNames'
  parent: app
  properties: {
    appSettingNames: [
      'WEBSITE_LOCAL_CACHE_OPTION'
    ]
  }
}

// resource appServiceAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
//   scope: existingAcr
//   name: guid(existingAcr.id, app.id, acrPullRoleDefinitionId)
//   properties: {
//     principalId: app.identity.principalId
//     roleDefinitionId: acrPullRoleDefinitionId
//     principalType: 'ServicePrincipal'
//   }
// }

// resource appServiceSlotAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
//   scope: existingAcr
//   name: guid(existingAcr.id, app::blueSlot.id, acrPullRoleDefinitionId)
//   properties: {
//     principalId: app::blueSlot.identity.principalId
//     roleDefinitionId: acrPullRoleDefinitionId
//     principalType: 'ServicePrincipal'
//   }
// }

output hostname string = app.properties.defaultHostName
output id string = app.id
