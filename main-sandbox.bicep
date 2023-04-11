// ** main bicep file ** //

@description('Azure region for the Resource Group')
param location string = 'eastus'

@description('Resource Group level deployment')
param deploymentName string = 'IaC-Deployment'

@description('Resource group for all deployed resources')
param resourceGroupName string = 'rg-default'

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = toLower('stg${uniqueString(subscription().id)}')



@description('Key Valut Name')
param keyVaultName string = 'kv-${resourceGroupName}'

@description('Data Factory Name')
param dataFactoryName string = 'adf-${resourceGroupName}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'


// Set Resource Tag Values
var tagID =  'sandbox'
var tagDeploy = 'IaC'

targetScope='subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags:{
    ID: tagID
    Deploy: tagDeploy
  }
}


// ** deploy resources into resoruce group
module adf './ADF-sandbox.bicep' = {
  scope: rg
  name: deploymentName
  params: {
    location:location
    storageAccountName: storageAccountName
    keyVaultName:keyVaultName
    dataFactoryName:dataFactoryName
    blobContainerName:blobContainerName

  }
}

