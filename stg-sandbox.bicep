//@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stg${resourceGroup().name}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'


// DLv2 Compatible Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location:  location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    isHnsEnabled:true
    accessTier:'Hot'
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: blobContainerName
    }

  }
//  tags:{
//    ID: tagID
//    Deploy: tagDeploy
}

//resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' ={
//  name: '${storageAccount.name}/default/${blobContainerName}'
//  dependsOn:[storageAccount]

var fileName = 'blob-1.txt'

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'dscript-upload-files'
//  dependsOn: [storageAccount]
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.40.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent(fileName)
      }
    ]
    
    storageAccountSettings:{
      storageAccountName:storageAccount.name
      storageAccountKey:storageAccount.listKeys().keys[0].value
    }

    scriptContent: 'echo "$CONTENT" > ${fileName} && az storage blob upload -f ${fileName} -c ${blobContainerName} -n ${fileName}'  }
}

output stgAccountName string = storageAccount.name
output containerName string = blobContainerName

//var sourceDir = 'C:/Users/bafri/OneDrive - KiZAN Technologies/AAG Best Practices/IaC/data'
//
//resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//  name: 'dscript-upload-files'
////  dependsOn: [storageAccount]
//  location: location
//  kind: 'AzureCLI'
//  properties: {
//    azCliVersion: '2.40.0'
//    timeout: 'PT5M'
//    retentionInterval: 'PT1H'
//    
//    
//    storageAccountSettings:{
//      storageAccountName:storageAccount.name
//      storageAccountKey:storageAccount.listKeys().keys[0].value
//    }
//
//    scriptContent: 'az storage blob upload-batch --account-name ${storageAccountName} --destination ${blobContainerName} --source ${sourceDir}'
//  }
//}

// **** AZ CLI command to load blob to storage account container

//scriptContent: 'az storage blob upload-batch --account-name ${storageAccountName} --destination ${blobContainerName} --source ./data'
//    scriptContent: 'echo "$CONTENT" > ${filename} && az storage blob upload -f ${filename} -c ${containerName} -n ${filename}'


//C:\Users\bafri>az storage blob upload -f c:\users\bafri\blob.txt --account-name storageaccountbfridley -c data -n AzureBlob.txt
//az storage blob upload-batch --account-name storageaccountbfridley --destination data --source ./data --pattern *.*
