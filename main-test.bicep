// ** main bicep file ** //

@description('Resource group to create')
param resourceGroupName string  = 'rg-default'

@description('Region for the Resource Group')
param location string
param tag string


// Set Resource Tag Values
//var tagID = 'sandbox'
var tagID =  'sandbox'
var tagDeploy = 'IaC'

targetScope='subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags:{
    ID: tag
    Deploy: tagDeploy
  }
}

// ** deploy resources into resoruce group
module adf './resource-test.bicep' = {
  scope: rg
  name: 'testDeployment'
  params: {
    tag:tag
    location:location    
  }
}



