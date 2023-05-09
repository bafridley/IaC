@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stg${resourceGroup().name}'

@description('Name of the blob container in the Azure Storage account.')
param blobContainerName string = 'data'

@description('user Assigne Managed Identity')
param uaManagedIDName string


// Name of file to upload to blobContainer
var fileName = 'employee.csv'


// User assigned managed identity to handle required permissions later in the deployment
resource managedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: uaManagedIDName
}



// **************************************************************************************************************
// Existing Storage Account
// Created in separate deployment script because dependencies not consistently enforced as expected.
// If dependency issue resolved, move Storeage Account deployment back to here.
// **************************************************************************************************************
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing =  {
  name: storageAccountName
}


// Defalut container for data files
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' ={
  name: '${storageAccount.name}/default/${blobContainerName}'
  dependsOn:[storageAccount]
}



// *** template for uploading batches of files at one time
var sourceDir = '/data'

resource deploymentScriptBatch 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'dscript-upload-batch-files'
  dependsOn: [blobContainer]
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.40.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    
    
    storageAccountSettings:{
      storageAccountName:storageAccount.name
      storageAccountKey:storageAccount.listKeys().keys[0].value
    }

    scriptContent: 'az storage blob upload-batch --account-name ${storageAccountName} --destination ${blobContainerName} --source ${sourceDir}'
  }
}



// **************************************************************************************************************
// Deployment script uploads text file stored in fileName variable to default blob container
// **************************************************************************************************************
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'dscript-upload-files'
  dependsOn: [blobContainer]
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

    scriptContent: 'echo "$CONTENT" > ${fileName} && az storage blob upload --overwrite -f ${fileName} -c ${blobContainerName} -n ${fileName}'  }
}





// Return blobCotainerName to be used elsewhere in deployment script
output blobContainerName string = blobContainerName


// *** template for uploading batches of files at one time
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
