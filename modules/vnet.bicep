param location string = resourceGroup().location
param name string
param vnetAddressPrefix string
param gatewaySubnetPrefix string
param integrationSubnetAddressPrefix string

// var affix = substring(uniqueString(resourceGroup().id), 0, 6)
// var vnetName = '${name}-${affix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: integrationSubnetAddressPrefix
          delegations: [
            {
              name: 'app-server-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

output vnet object = vnet
output vnetId string = vnet.id
output vnetName string = vnet.name
output gatewaySubnetId string = vnet.properties.subnets[0].id
output integrationSubnetId string = vnet.properties.subnets[1].id
