param storageAccountName string


// Need to create as DLv2 capable

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    isHnsEnabled:true
    accessTier:'Cool'
  }

}

/*

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' ={
  name:'toy-product-launch-plan-starter'
  location:'westus3'
  sku:{
    name:'F1'
  }
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01'={
  name:'bfridley-toy-product-launch'
  location:'westus3'
  properties:{
    serverFarmId:appServicePlan.id
    httpsOnly:true
  }
}

*/


