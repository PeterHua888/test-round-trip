param acrName string
param appNameUK string
param appNameHK string
param aspNameUK string
param aspNameHK string
param vnetNameUK string
param vnetNameHK string
param regionUK string
param regionHK string
param containerPort string = '8000'
param imageNameAndTagUK string
param imageNameAndTagHK string
param vnetAddressUK string
param vnetAddressHK string
param gatewaySubnetAddressUK string
param gatewaySubnetAddressHK string
param integrationSubnetAddressUK string
param integrationSubnetAddressHK string

// App Settings
param acrUseManagedIdentityCreds bool
param vnetRouteAllEnabled bool
param clientAffinityEnabled bool
param httpLogsEnabled bool
param httpLogsRetentionDays int
param httpLogsRetentionMb int
param serverEnvironment string

// module acrModule 'modules/acr.bicep' = {
//   name: 'acr-deployment'
//   params: {
//     location: region
//     name: name
//   }
// }

module vnetUKSouthModule 'modules/vnet.bicep' = {
  name: '${regionUK}-vnet-deployment'
  params: {
    location: regionUK
    name: vnetNameUK
    vnetAddressPrefix: vnetAddressUK
    gatewaySubnetPrefix: gatewaySubnetAddressUK
    integrationSubnetAddressPrefix: integrationSubnetAddressUK
  }
}

module vnetEastasiaModule 'modules/vnet.bicep' = {
  name: '${regionHK}-vnet-deployment'
  params: {
    location: regionHK
    name: vnetNameHK
    vnetAddressPrefix: vnetAddressHK
    gatewaySubnetPrefix: gatewaySubnetAddressHK
    integrationSubnetAddressPrefix: integrationSubnetAddressHK
  }
}

// Peer vnets
module UKSouthToEastasiaPeer 'modules/peering.bicep' = {
  name: '${regionUK}-to-${regionHK}-peer'
  params: {
    localVnetName: vnetUKSouthModule.outputs.vnetName
    remoteVnetName: vnetEastasiaModule.outputs.vnetName
    remoteVnetId: vnetEastasiaModule.outputs.vnetId
  }
}

module EastasiaToUKSouthPeer 'modules/peering.bicep' = {
  name: '${regionHK}-to-${regionUK}-peer'
  params: {
    localVnetName: vnetEastasiaModule.outputs.vnetName
    remoteVnetName: vnetUKSouthModule.outputs.vnetName
    remoteVnetId: vnetUKSouthModule.outputs.vnetId
  }
}

module appUKSouthModule 'modules/app.bicep' = {
  name: '${regionUK}-app-deployment'
  params: {
    location: regionUK
    acrName: acrName
    appName: appNameUK
    aspName: aspNameUK
    containerPort: containerPort
    imageNameAndTag: imageNameAndTagUK
    vnetIntegrationSubnetId: vnetUKSouthModule.outputs.integrationSubnetId
    acrUseManagedIdentityCreds: acrUseManagedIdentityCreds
    vnetRouteAllEnabled: vnetRouteAllEnabled
    clientAffinityEnabled: clientAffinityEnabled
    httpLogsEnabled: httpLogsEnabled
    httpLogsRetentionDays: httpLogsRetentionDays
    httpLogsRetentionMb: httpLogsRetentionMb
    serverEnvironment: serverEnvironment
  }
}

module appEastasiaModule 'modules/app.bicep' = {
  name: '${regionHK}-app-deployment'
  params: {
    location: regionHK
    acrName: acrName
    appName: appNameHK
    aspName: aspNameHK
    containerPort: containerPort
    imageNameAndTag: imageNameAndTagHK
    vnetIntegrationSubnetId: vnetEastasiaModule.outputs.integrationSubnetId
    acrUseManagedIdentityCreds: acrUseManagedIdentityCreds
    vnetRouteAllEnabled: vnetRouteAllEnabled
    clientAffinityEnabled: clientAffinityEnabled
    httpLogsEnabled: httpLogsEnabled
    httpLogsRetentionDays: httpLogsRetentionDays
    httpLogsRetentionMb: httpLogsRetentionMb
    serverEnvironment: serverEnvironment
  }
}
