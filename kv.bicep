// ***************************************************************************************************************
// ***** RESET Deploymenet *****
// ***** purge keyvault after soft-delete *****
// az keyvault list-deleted --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 --resource-type vault
// az keyvault purge --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 -n kv-kizan-sandbox
// ***************************************************************************************************************


@description('Location of the resources')
param location string = resourceGroup().location

@description('Key Valut Name')
param keyVaultName string = 'kv-${resourceGroup().name}'

@description('Storage Account Name for Key Vault access key')
param storageAccountName string

@description('user Assigne Managed Identity')
param uaManagedIDName string


// Temporarily hard-code personal objectID to allow admin access to KeyVault
var objectID = '194da7d9-e9eb-454d-a07a-4f68b547f960'


// ************************************************
// Existing Storage Account created earlier
// ************************************************
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing =  {
  name: storageAccountName
}


// ***************************************************************************
// User assigned managed identity created previously 
// Managed Identity used for required permissions later in the deployment
// ***************************************************************************
resource managedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uaManagedIDName
}


// ***************************************************************************************************
// Use the system predefined Contributor Role ()'b24988ac-6180-42a0-ab88-20f7382dd24c')
// Give Contributor role to Managed Identity to handle required permissions later in the deployment
// ***************************************************************************************************
resource roleDefinitionContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing ={
  scope:subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'

}


// ************************************************************************************************************
// Add Contributor role assignment to Managed Identity to handle required permissions later in the deployment
// ************************************************************************************************************
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01'={
  name:guid(resourceGroup().id,uaManagedIDName, roleDefinitionContributor.id)
  properties:{
    roleDefinitionId:roleDefinitionContributor.id
    principalId:managedID.properties.principalId
    principalType:'ServicePrincipal'
  }
}


//***************************************************************************************************
// Key Vault deployment will fail if the named key-vault existed before and is soft-deleted
// Will provide Az CLI deployment script to purge soft-deleted key vaults when time permits
// In the meantime, manually purge key vaults with:
// az keyvault purge --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 -n kv-kizan-sandbox
//***************************************************************************************************


// ***************************************************************************************************
// Deployment script failing with error message:
// The template function 'reference' is not expected at this location.
// Until resolved, Soft-Deleted Key Vaults must be removed manually prior to re-deployment
// ***************************************************************************************************
/*
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'dscript-purge-deleted-vaults'
  dependsOn: [storageAccount]
  location: location
  kind: 'AzureCLI'
  identity:{
    type:'UserAssigned'
    userAssignedIdentities:managedID
  }
  properties: {
    azCliVersion: '2.40.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    
    storageAccountSettings:{
      storageAccountName:storageAccount.name
      storageAccountKey:storageAccount.listKeys().keys[0].value
    }

    scriptContent: 'az keyvault purge -n ${keyVaultName}'  
  }
}
// *************************************************************************************************** */



// *****************************************************************
// *********** KEY VAULT RESOURCES ********** 
// *****************************************************************
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01'= {
  name: keyVaultName
//  dependsOn:[deploymentScript]
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId

    accessPolicies: [
      // During development, give access to personal PrinicipalID 
      // Remove when complete
      {
        objectId: objectID
        tenantId: tenant().tenantId
        permissions: {
          secrets:['list','get']
        }
      }

      // Give Key Vault access to User Assigned Managed Identity created previously
      {
        objectId: managedID.properties.principalId
        tenantId: tenant().tenantId
        permissions: {
          secrets:['list','get']
        }
      }
    ]

  }
}

// Dummy Secret to test access to Key Vault
resource secretDummy 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'sandbox-secret'
  properties: {
    value: 'SecretValue'
  }

}


// Return Key Vault Name to be used elsewhere in deployment
output keyVaultName string = keyVault.name
