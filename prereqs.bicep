// ***********************************************************************************************************************
// Used separate deployment for Storage Account to ensure its successfully created before container and files are uploaded.
// Parent and DependsOn properties did not enforce dependencies (althrough it should have)
// ***********************************************************************************************************************
// This is a work-around until the dependency problem can be resolved
// ***********************************************************************************************************************
@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = 'stg${resourceGroup().name}'

@description('Name of the User Assigned Managed Identity created to handle required permissions later in the deployment')
param managedIdentityName string = 'idIaC'


// ***** Storage Account used later in deployment ***** //
// Storage Account deployed as pre-req because dependencies (Parent or DependsOn properties) not consistently functioning as intended
// deployed as separate, staged event to ensure Storeage Account is availalbe when needed elsewhere.
// If dependencies operate as expected, move this deployment to other storage (blob, files, etc.) deployment file
// ****** ***************************************** ***** //
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

}




// create user assigned managed identity to handle required permissions later in the deployment
resource managedID 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}


// Return output parameters to use elsewhere in deployment
output storageAccountName string = storageAccount.name
output uaManagedIDName string = managedID.name
