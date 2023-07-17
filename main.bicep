// CLI commands to deploy bicep file
// az deployment sub what-if --template-file main.bicep --parameters parameters.jsonc --location eastus
// az deployment sub create --template-file main.bicep --parameters parameters.jsonc --location eastus



// ********************* //
// ** main bicep file ** //
// ********************* //

// parameter values will come from a parameters file if specified
// otherwise, the values provided in commandline or default values will be used 

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
param managedIdentityName string = 'idADF'



/* *********************************************************
// ********************************************
// Examples of additional parameter decorators
// ********************************************

// @secure parameters are not saved to deployment history or logged
// Not visibile in the Azure portal
@secure()
param adminPassword string

@maxLength(11)
param storagePrefix string = 'stg'

@allowed([
  'Standard_LRS','Standard_GRS','Standard_RAGRS','Standard_ZRS','Premium_LRS'
])
param storageAccountType string
********************************************************* */



// *****************************************************************************
// Scope the deployments at Subscription level to create a new Resource Group
// *****************************************************************************
targetScope='subscription'



// ****************************************************************
// Create new Resource Group for all new resources
// ****************************************************************
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}



// ************************************************************************************************
// Deploy base storage account used by other resources
// Would be cleaner to deploy in stg deployment along with container and other file activities
// Moved into separate module as work-around to inconsistent dependency problems where
// Container would occasionally be deployed before Storage Account (reulting in failure)
// Setting DependsOn and Parent properties did not resolve the issue
// ************************************************************************************************
module prereqs './prereqs.bicep'={
  scope:rg // Scope to the Resource Group created above
  dependsOn:[rg]
  name:'prereqsDeployment'
  params:{
    location:location
    storageAccountName:storageAccountName
    managedIdentityName:managedIdentityName
  }
}

// ****************************************************************
// Deploy Key Vault that will be used by other resources
// Key Vault is used to store secrets and connection strings
// ****************************************************************
module kv './kv.bicep' = {
  scope:rg // Scope to the Resource Group created above
  dependsOn:[prereqs]
  name:'kvDeployment'
  params:{
    location:location
    keyVaultName:keyVaultName
    storageAccountName:storageAccountName
    uaManagedIDName:prereqs.outputs.uaManagedIDName
  }
}


// ****************************************************************
// Deploy Storage account, container and upload sample data
// ****************************************************************
module stg './stg.bicep'={
  scope:rg // Scope to the Resource Group created above
  dependsOn:[kv]
  name:'stgDeplyment'
  params:{
    location:location
    storageAccountName:storageAccountName
    blobContainerName:blobContainerName
    keyVaultName:keyVaultName
    uaManagedIDName:prereqs.outputs.uaManagedIDName
  }
}



// ****************************************************************
// Deploy SQL Server and sample database
// ****************************************************************
module sql './sql.bicep'={
  scope:rg // Scope to the Resource Group created above
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



// ****************************************************************
// ***** Deploy Azure DataFactory resources into resoruce group 
// ****************************************************************
module adf './adf.bicep' = {
  scope: rg // Scope to the Resource Group created above
  name: 'adfDeployment'
  dependsOn:[kv,stg,sql]

  // using qualified object.property notation below will also enforce dependency
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

