targetScope = 'resourceGroup'

param resourcePrefix string = 'mv'
@minLength(2)
param name string = 'demo'
@minLength(3)
@maxLength(3)
param locationShort string = 'weu'

var storageAccountName = '${resourcePrefix}${name}sa${locationShort}'
var userAssignedManagedIdentityName = '${resourcePrefix}-${name}-id-${locationShort}'

// References to existing resources
// Storage account
resource refStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// User assigned managed identity
resource refUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: userAssignedManagedIdentityName
}

// RBAC assignments
// User assigned managed identity may contribute to the storage account
resource accessConnectorStorageAccountBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(refStorageAccount.id, userAssignedManagedIdentityName, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: refStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: refUserAssignedManagedIdentity.properties.principalId
  }
}
