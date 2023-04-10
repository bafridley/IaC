

@description('Generated from /subscriptions/90d2d107-4965-4e5d-862b-8618c111f1f8/resourceGroups/rg-adf-bfridley/providers/Microsoft.DataFactory/factories/adf-bfridley')
resource adfbfridley 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-bfridley'
  properties: {
    factoryStatistics: {
      totalResourceCount: 0
      maxAllowedResourceCount: 0
      factorySizeInGbUnits: 0
      maxAllowedFactorySizeInGbUnits: 0
    }
    globalParameters: {
      P1: {
        type: 'string'
        value: 'PPP'
      }
    }
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
    publicNetworkAccess: 'Enabled'
    globalConfigurations: {
      PipelineBillingEnabled: 'true'
    }
  }
  location: 'eastus'
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/90d2d107-4965-4e5d-862b-8618c111f1f8/resourcegroups/rg-adf-bfridley/providers/Microsoft.ManagedIdentity/userAssignedIdentities/adf-id': {
        clientId: '2ad43bc1-6518-4a74-827f-4b840d65bb97'
        principalId: 'f832e321-a7a1-49a5-b7de-4b2272394248'
      }
    }
  }
  tags: {
    ID: 'ADF Container'
  }
}

// ********************************** //

@description('Data Factory Name')
param dataFactoryName string = 'datafactory${uniqueString(resourceGroup().id)}'

@description('Location of the data factory.')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'blob${uniqueString(resourceGroup().id)}'

var dataFactoryLinkedServiceName = 'ArmtemplateStorageLinkedService'
var dataFactoryDataSetInName = 'ArmtemplateTestDatasetIn'
var dataFactoryDataSetOutName = 'ArmtemplateTestDatasetOut'
var pipelineName = 'ArmtemplateSampleCopyPipeline'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccount.name}/default/${blobContainerName}'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryLinkedServiceName
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
    }
  }
}

resource dataFactoryDataSetIn 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryDataSetInName
  properties: {
    linkedServiceName: {
      referenceName: dataFactoryLinkedService.name
      type: 'LinkedServiceReference'
    }
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainerName
        folderPath: 'input'
        fileName: 'emp.txt'
      }
    }
  }
}

resource dataFactoryDataSetOut 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryDataSetOutName
  properties: {
    linkedServiceName: {
      referenceName: dataFactoryLinkedService.name
      type: 'LinkedServiceReference'
    }
    type: 'Binary'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: blobContainerName
        folderPath: 'output'
      }
    }
  }
}

resource dataFactoryPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: pipelineName
  properties: {
    activities: [
      {
        name: 'MyCopyActivity'
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BinarySource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
            }
          }
          sink: {
            type: 'BinarySink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
            }
          }
          enableStaging: false
        }
        inputs: [
          {
            referenceName: dataFactoryDataSetIn.name
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: dataFactoryDataSetOut.name
            type: 'DatasetReference'
          }
        ]
      }
    ]
  }
}
