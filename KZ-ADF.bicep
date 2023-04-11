@description('Location of the data factory.')
param location string = resourceGroup().location

@description('Data Factory Name')
param dataFactoryName string = 'adf-kizan-model'

@description('Key Valut Name')
param keyVaultName string = 'kv-kizan-model'

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stgkizanmodel'


@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'


// Set Resource Tag Values
var tagID = 'KZ-Model'
var tagDeploy = 'IaC'

var storageAccountAccessKeySecretName = 'storage-account-access-key'

var dataFactoryBlobLinkedServiceName = 'AzureBlob'
var dataFactorySQLLinkedServiceName = 'AzureSQL'

var dataFactoryCSVDataSet = 'CSV_parameters'
var dataFactorySQLDataSet = 'SQL_parameters'

var dataFactoryPipeline = 'CopyData_parameters'



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
    ID:  tagID
    Deploy: tagDeploy
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' ={
  name: '${storageAccount.name}/default/${blobContainerName}'
  dependsOn:[storageAccount]
}


// **** Azure Data Factory Resource **** //
@description('KiZAn Azure Data Factory Model')
resource adfkz 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type:'SystemAssigned'
  }

  properties: {

    globalParameters: {
      GlobalParm: {
        type: 'string'
        value: 'default'
      }
    }
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
*/
  }

  tags:{
    ID:  tagID
    Deploy: tagDeploy
  }
}


resource dataFactoryBlobLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: adfkz
  name: dataFactoryBlobLinkedServiceName
  properties: {
    annotations:[]
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
    }
  }
}

