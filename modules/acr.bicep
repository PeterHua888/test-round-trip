param location string = 'eastasia'
param name string
// var affix = substring(uniqueString(resourceGroup().id), 0, 6)

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7 // The number of days to retain an untagged manifest after which it gets purged
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false // Enable a single data endpoint per region for serving data
    publicNetworkAccess: 'Enabled' // Whether or not public network access is allowed for the container registry
    networkRuleBypassOptions: 'AzureServices' // Whether to allow trusted Azure services to access a network restricted registry
    zoneRedundancy: 'Disabled' // Whether or not zone redundancy is enabled for this container registry
  }
}

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
