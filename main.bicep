// ** main bicep file ** //

@description('Azure region for the Resource Group')
param location string = 'eastus'

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

@description('Name of the User Assigned Managed Identity used for deplyment permissions')
param managedIdentityName string = 'IaC'

// Scope all deployments at Subscription level
targetScope='subscription'

// Create new Resource Group for all new resources
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

// Deploy base storage account used by other resources
// Would be cleaner to deploy in stg deployment along with container and other file activities
// Moved into separate module as work-around to inconsistent dependency problems where
// Container would occasionally be deployed before Storage Account (reulting in failure)
// Setting DependsOn and Parent properties did not resolve the issue
module prereqs './prereqs.bicep'={
  scope:rg
  dependsOn:[rg]
  name:'prereqsDeployment'
  params:{
    location:location
    storageAccountName:storageAccountName
    managedIdentityName:managedIdentityName
  }
}

// Deploy Key Vault that will be used by other resources
module kv './kv.bicep' = {
  scope:rg
  dependsOn:[prereqs]
  name:'kvDeployment'
  params:{
    location:location
    keyVaultName:keyVaultName
    storageAccountName:storageAccountName
    uaManagedIDName:prereqs.outputs.uaManagedIDName
  }
}

// Deploy Storage account, container and upload sample data
module stg './stg.bicep'={
  scope:rg
  dependsOn:[kv]
  name:'stgDeplyment'
  params:{
    location:location
    storageAccountName:storageAccountName
    blobContainerName:blobContainerName
    keyVaultName:keyVaultName
  }
}


// Deploy SQL Server and sample database
module sql './sql.bicep'={
  scope:rg
  dependsOn:[kv]
  name:'sqlDeployment'
  params:{
    location:location
    sqlServerName: 'sql${uniqueString(rg.id)}'
//    sqlServerName: uniqueString('sqlKZDemo',rg.id)
    sqlDBName:'demo'
    keyVaultName:keyVaultName
  }
}


// ***** Deploy Azure DataFactory resources into resoruce group ***
module adf './adf.bicep' = {
  scope: rg
  name: 'adfDeployment'
// User output variables of other modeules as input to ADF module parameters to force dependency
  params: {
    location:location
    storageAccountName: prereqs.outputs.storageAccountName
    keyVaultName:kv.outputs.keyVaultName
    dataFactoryName:dataFactoryName
    blobContainerName:stg.outputs.blobContainerName
    sqlServerName:sql.outputs.sqlServerName
    sqlDBName:sql.outputs.sqlDBName
  }
}

