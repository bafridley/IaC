// ** main bicep file ** //

@description('Region for the Resource Group')
param location string = 'eastus'

// Set Resource Tag Values
var tagID = 'sandbox'
var tagDeploy = 'IaC'

targetScope='subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-sandbox'
  location: location
  tags:{
    ID: tagID
    Deploy: tagDeploy
  }
}

// ** deploy resources into resoruce group
module adf './ADF-sandbox.bicep' = {
  scope: rg
  name: 'SandboxDeployment'
//  params: {
//    storageAccountName:'bfridleysandbox2storage'
//  }
}
