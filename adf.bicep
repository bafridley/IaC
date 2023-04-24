// ***************************************************************************************************************
// ***** RESET Deploymenet *****
// ***** purge keyvault after soft-delete *****
// az keyvault list-deleted --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 --resource-type vault
// az keyvault purge --subscription 90d2d107-4965-4e5d-862b-8618c111f1f8 -n kv-kizan-sandbox
// ***************************************************************************************************************

//@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stg${resourceGroup().name}'

@description('Key Valut Name')
param keyVaultName string = 'kv-${resourceGroup().name}'

@description('Data Factory Name')
param dataFactoryName string = 'adf-${resourceGroup().name}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'

@description('Name of the Azure SQL Server')
param sqlServerName string = 'sql${uniqueString(resourceGroup().id)}'

@description('Default SQL Database')
param sqlDBName string='demo'


var stgAccountConnectionStringSecretName = 'storageAccountConnectionString'
var sqlServerConnectionStringSecretName = 'sqlDBConnectionString'
var dataFactoryBlobLinkedServiceName = 'AzureBlob'
var dataFactorySQLLinkedServiceName = 'AzureSQL'
var dataFacotryKVLinkedServiceName = 'AzureKV'
var dataFactoryCSVDataSetName = 'CSV_Parameters'
var dataFactorySQLDataSetName = 'SQL_Parameters'
var dataFactoryPipelineName = 'CopyData_parameters'


// *********** EXISTING RESOURCES USED IN DEPLOYMENT **********
// Reference existing storage account for linked service 
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
	name: storageAccountName
}


// Reference existing SQL Server for linked service 
resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview'existing ={
  name:sqlServerName
}
// Reference existing SQL Database for linked service 
resource sqlDB 'Microsoft.Sql/servers/databases@2022-08-01-preview'existing={
  parent:sqlServer
  name:sqlDBName
}


// *********** AZURE DATA FACTORY RESOURCES ********** //
@description('KiZAN Azure Data Factory Model')
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
	name: dataFactoryName
	location: location
	identity: {
    type:'SystemAssigned'
// Eventually want to use User Assigned Managed Identity
//    userAssignedIdentities:{
//      '/subscriptions/90d2d107-4965-4e5d-862b-8618c111f1f8/resourcegroups/rg-kizan-sandbox/providers/Microsoft.ManagedIdentity/userAssignedIdentities/idADF': {
////        clientId: 'e9fcd989-993c-49fd-be74-6676f9f2fc0e'
//        principalId: idADF.id
//      } 
//    }
	}

	properties: {
    publicNetworkAccess: 'Enabled'

    // *****************************************************
    // Global parameters across entire Data Factory
    // *****************************************************
    globalParameters: {
      testGlobalParm: {
        type: 'string'
        value: 'default'
      }
    }
  }

/* 
// ***** Git Repo Configuration goes here ******
// ***** Supply desired Git Account and Repo name  *****
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

}

// ***** Use existing Key Vault created elsehwere in deployment *****
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name:keyVaultName
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

// ***** Data Factory Key Vault Linked Service *****
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

// ***** Data Factory Azure Blob Linked Service *****
resource dataFactoryBlobLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  dependsOn:[dataFactoryKeyVaultLinkedService]
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
        secretName: stgAccountConnectionStringSecretName
      }
    }
    }
  }

// ***** Data Factory SQL Server Linked Service *****
resource dataFactorySQLLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01'={
  parent:dataFactory
  dependsOn:[dataFactoryKeyVaultLinkedService]
  name:dataFactorySQLLinkedServiceName
  properties:{
    annotations:[]
    description:'Linked Service for SQL Server'
    type:'AzureSqlDatabase'
    typeProperties:{
      connectionString:{
        type:'AzureKeyVaultSecret'
        store:{
          referenceName:dataFacotryKVLinkedServiceName
          type:'LinkedServiceReference'
        }
        secretName: sqlServerConnectionStringSecretName
      }
    }
  }
}

// ***** Data Factory CSV Linked Service
resource dataFactoryCSVDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactoryCSVDataSetName
  properties: {
    linkedServiceName:{
      referenceName: dataFactoryBlobLinkedService.name
      type: 'LinkedServiceReference'
    }
    parameters:{
      FileName: {
        type:'String'
//        defaultValue:'data.txt'
      }
    }
    
    type:'DelimitedText'
    typeProperties:{
      location:{
        type:'AzureBlobStorageLocation'
        fileName:{
          value: '@dataset().FileName'
          type: 'Expression'
        }
        container:blobContainerName
      }
      columnDelimiter:','
      escapeChar:'\\'
      firstRowAsHeader:'true'
      quoteChar:'"'
    }
    
  }

}

resource dataFactorySQLDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: dataFactorySQLDataSetName
  properties: {
    linkedServiceName:{
      referenceName: dataFactorySQLLinkedService.name
      type: 'LinkedServiceReference'
    }
    parameters:{
      TableName: {
        type:'String'
//        defaultValue:'tableName'
      }
    }
    
    type:'AzureSqlTable'
    schema:[]
    typeProperties:{
      schema:'demo'
      table:{
        value:'@dataset().TableName'
        type:'Expression'
      }
    }
    
  }
} 


resource dataFactoryPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01'={
  parent:dataFactory
  name: dataFactoryPipelineName
  dependsOn:[dataFactorySQLDataset, dataFactoryCSVDataset]
  properties: {

    parameters: {
      source: {
        type: 'string'
      }
      destination: {
        type: 'string'
      }
    }

    activities: [
      {
        name: 'CopyFromCSVtoSQL'
        description: 'Use parameterized Linked Services to copy from CSV to SQL Server DB'
        type: 'Copy'
        dependsOn: []
        
        policy: {
          timeout: '0.12:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }

        userProperties: []
        
        typeProperties: {
        
          source: {
            type: 'DelimitedTextSource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
              enablePartitionDiscovery: false
            }
            formatSettings: {
                type: 'DelimitedTextReadSettings'
            }
            }
        
        sink: {
            type: 'AzureSqlSink'
            writeBehavior: 'insert'
            sqlWriterUseTableLock: false
            tableOption: 'autoCreate'
            disableMetricsCollection: false
        }
        
          enableStaging: false
        
          translator: {
            type: 'TabularTranslator'
            typeConversion: true
            typeConversionSettings: {
              allowDataTruncation: true
              treatBooleanAsNumber: false
            }
          }
        }

        inputs: [
          {
            referenceName: dataFactoryCSVDataset.name
            type: 'DatasetReference'
            parameters: {
              FileName: {
                value: '@pipeline().parameters.source'
                type: 'Expression'
              }
            }
          }
        ]

        outputs: [
          {
            referenceName: dataFactorySQLDataset.name
            type: 'DatasetReference'
            parameters: {
              TableName: {
                value: '@pipeline().parameters.destination'
                type: 'Expression'
              }
            }
          }
        ]
      }
    ]

    annotations: []
  }

}
