
@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the Azure SQL Server')
param sqlServerName string = 'sql${uniqueString(resourceGroup().id)}'

@description('Default SQL Database')
param sqlDBName string='demo'

@description('Name of the blob container in the Azure Storage account.')
param keyVaultName string = 'data'


// *** hard-coded secrets approach is temporary
var saLogin = 'kzSA'
var saPassword = 'pass@word1'

// *************************************************************************
// Default SQL Server used in ADF Linked Services and Pipelines
// *************************************************************************
resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview'={
  name:sqlServerName
  location:location
  identity: {
    type:'SystemAssigned'
  }
  properties:{
    administratorLogin:saLogin
    administratorLoginPassword:saPassword
  }
}

// ******************************************************************************
// Default SQL Server Database used in ADF Linked Services and Pipelines
// ******************************************************************************
resource sqlDB 'Microsoft.Sql/servers/databases@2022-08-01-preview'={
  parent:sqlServer
  name:sqlDBName
  location:location
  sku:{
    name:'standard'
    tier:'standard'
  }

}

// *********************************************************************************************************
// Requred to set flag to allow firewall exception allowing Azure Services access to SQL Server
// This is necessary for ADF Linked Services to work with SQL Server
// *********************************************************************************************************
resource SQLAllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}


// *********** Create Key Vault Secrets for SQL Server Access **********

// Reference existing storage account for linked service 
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}


// SQL Server connection string secret info
var sqlDBConnectionStringSecretName = 'sqlDBConnectionString'
var sqlDBConnectionString = 'Server=tcp:${sqlServer.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDB.name};Persist Security Info=False;User ID=${sqlServer.properties.administratorLogin};Password=${saPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'


// Create SQL Server DB connection string secret for linked service
resource secretSQLDBConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: sqlDBConnectionStringSecretName
  properties: {
    value:  sqlDBConnectionString
  }
}


// Return values for use elsewhere in deployment
output sqlServerName string = sqlServer.name
output sqlDBName string = sqlDB.name
