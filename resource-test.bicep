// ***************************************************************************************************************
// ***** purge keyvault after soft-delete *****
// az keyvault list-deleted --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 --resource-type vault
// az keyvault purge --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 -n kv-kizan-sandbox
// ***************************************************************************************************************

//@description('Location of the resources')
//param location string = resourceGroup().location
param location string 
param tag string

param storageAccountName string  = 'stgkzdefault'

// *** Variable Declarations ***
// Set Resource Tag Values
var tagID = 'sandbox'
var tagDeploy = 'IaC'
var objectID = '194da7d9-e9eb-454d-a07a-4f68b547f960'


// DLv2 Compatible Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    isHnsEnabled:true
    accessTier:'Hot'
  }

  tags:{
    ID: tag
    Deploy: tagDeploy
  }

}

//output storageAccountKey string = listKeys(storageAccount.id,'2022-09-01').keys[0].value




/*
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' ={
  name: '${storageAccount.name}/default/${blobContainerName}'
  dependsOn:[storageAccount]
}

var storageAccessKey = storageAccount.listKeys().keys[0].value
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccessKey};EndpointSuffix=core.windows.net'

output storageName string = storageAccount.name

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01'= {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId

    accessPolicies: [
      {
        objectId: objectID
        tenantId: tenant().tenantId
        permissions: {
          secrets:['list','get']
        }
      }
    ]

  }

  tags:{
    ID: tagID
    Deploy: tagDeploy
  }

}

resource secretDummy 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'sandbox-secret'
  properties: {
    value: 'SecretValue'
  }
  tags:{
    ID: tagID
    Deploy: tagDeploy
  }
}

resource secretStorageAccountKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: storageAccountAccessKeySecretName
  properties: {
    value: storageAccessKey
  }
  tags:{
    ID: tagID
    Deploy: tagDeploy
  }
}

resource secretStorageConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: storageAccountConnectionStringSecretName
  properties: {
    value:  storageConnectionString
  }
  tags:{
    ID: tagID
    Deploy: tagDeploy
  }

}

// **** Azure Data Factory Resource **** //
@description('KiZAn Azure Data Factory Model')
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type:'SystemAssigned'
  }

  properties: {
    publicNetworkAccess: 'Enabled'
    globalParameters: {
      GlobalParm: {
        type: 'string'
        value: 'default'
      }
    }
  }
*/



/* -- configure repo integration later
    repoConfiguration: {
      type: 'FactoryGitHubConfiguration'
      hostName: ''
      accountName: 'bafridley'
      repositoryName: 'adflearn'
      collaborationBranch: 'main'
      rootFolder: '/'
      lastCommitId: '096d79ffaa2960a66d84a834c7a2856e2dec030b'
      disablePublish: false
    }
  }
*/


/*
  tags: {
    ID: tagID
    Deploy: tagDeploy
  }
}

// *** Add an access policy to Key Vault for Azure Data Factory ***
resource keyValutAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01'={
  parent:keyVault
  name:'add'
  dependsOn:[dataFactory]
  properties:{
    accessPolicies:[
      {
        objectId:dataFactory.identity.principalId
        tenantId:tenant().tenantId
        permissions:{
          secrets:['list','get']
        }
      }
    ]
  }

}

// *** Data Factory Key Vault Linked Service *** //
resource dataFactoryKeyVaultLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: dataFacotryKVLinkedServiceName
  parent:dataFactory
  properties: {
    annotations:[]
    type:'AzureKeyVault'
    typeProperties:{
      baseUrl:keyVault.properties.vaultUri
    }
  }
}

// *** Azure Blob Linked Service
resource dataFactoryBlobLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
//  dependsOn:blobContainer
  name: dataFactoryBlobLinkedServiceName
  properties: {
    annotations:[]
    description: 'Linked Service for Azure Blob Storage'
    type : 'AzureBlobStorage'
    typeProperties: {
      connectionString : {
        type: 'AzureKeyVaultSecret'
        store:{
          referenceName:dataFacotryKVLinkedServiceName
          type: 'LinkedServiceReference'
        }
        secretName: storageAccountConnectionStringSecretName
      }
      }
    }
  }

  */

