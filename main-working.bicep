// CLI commands to deploy bicep file
// az deployment sub create --template-file main.bicep --parameters parameters.jsonc --location eastus  

// ** main bicep file ** //

@description('Azure region for the Resource Group')
param location string = 'eastus'

@description('Resource group for all deployed resources')
param resourceGroupName string = 'rg-default'

@description('Name of the Azure storage account that contains the input/output data.')
param storageAccountName string = toLower('stg${uniqueString(subscription().id)}')


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


// Deploy Storage account, container and upload sample data
module stg './stg-working.bicep'={
  scope:rg
  dependsOn:[prereqs]
  name:'stgDeplyment'
  params:{
    location:location
    storageAccountName:storageAccountName
    blobContainerName:blobContainerName
    uaManagedIDName:prereqs.outputs.uaManagedIDName
  }
}


