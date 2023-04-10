
@description('Location of the data factory.')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stgsandbox'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'



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
    ID: 'sandbox'
    Deploy: 'IaC'
  }
}

output storageAccountKey string = listKeys(storageAccount.id, '2021-04-01').keys[0].value

// return name of the created storage account
output name string = storageAccount.name


resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' ={
  name: '${storageAccount.name}/default/${blobContainerName}'
  dependsOn:[storageAccount]
}
