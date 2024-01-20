targetScope = 'resourceGroup'

param resourcePrefix string = 'mv'
@minLength(2)
param name string = 'demo'
param location string = 'westeurope'
@minLength(3)
@maxLength(3)
param locationShort string = 'weu'

var storageAccountName = '${resourcePrefix}${name}sa${locationShort}'
var databricksWorkspaceName = '${resourcePrefix}-${name}-dws-${locationShort}'
var databricksAccessConnectorName = '${resourcePrefix}-${name}-acc-${locationShort}'
var managedResourceGroupName = '${resourcePrefix}-${name}-managed-rg-${locationShort}'
var userAssignedManagedIdentityName = '${resourcePrefix}-${name}-id-${locationShort}'

var tags = {
  environment: 'demo'
  startDate : '2024-01-20'
}
// Existing resources
resource refManagedResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}

// New resources
// Storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for containerName in ['raw', 'delta']: {
  parent: blobService
  name: containerName
}]

// Databricks workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksWorkspaceName
  location: location
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: refManagedResourceGroup.id
  }
  tags: tags
}

// User assigned managed identity
resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: userAssignedManagedIdentityName
  location: location
  tags: tags
}

// Databricks access connector
resource databricksAccessConnector 'Microsoft.Databricks/accessConnectors@2023-05-01' = {
  name: databricksAccessConnectorName
  location: location  
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
}

// rbac assignments
module modRbac 'rbac.bicep' = {
  name: 'modRbac'
  dependsOn: [
    storageAccount
    databricksWorkspace
    databricksAccessConnector
  ]
  params: {
    name: name
    locationShort: locationShort
    resourcePrefix: resourcePrefix
  }
}
