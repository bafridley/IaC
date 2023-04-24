param adfName string = '<Name of Data Factory>'
param dsBlob string = '<Name of blob storage dataset>'
param dsSqlTable string = '<Name of SQL DB table dataset>'
param lsSqlDb string = '<Name of linked service for SQL DB>'
param lsBlob string = '<Name of linked service for Azure storage account>'
param pipeline string = '<Name of pipeline to copy the data>'

var connBlob = '<Connection string of Azure storage account>'
var connSqlDb = '<Connection string of SQL DB>'
var rgLocation = resourceGroup().location

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: rgLocation
  properties: {}
}

resource adfLsBlob 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${adf.name}/${lsBlob}'
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: connBlob
    }
  }
  dependsOn: [ 
    adf
  ]
}

resource adfLsSqlDb 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${adf.name}/${lsSqlDb}'
  properties: {
    type: 'AzureSqlDatabase'
    typeProperties: {
      connectionString: connSqlDb
    }
  }
}

resource adfDatasetBlob 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${adf.name}/${dsBlob}'
  properties: {
    type: 'DelimitedText'
    linkedServiceName: {
      referenceName: lsBlob
      type: 'LinkedServiceReference'
    }
    schema: [
      {
        name: 'ID'
        type: 'String'
        physicalType: 'String'
      }
      {
        name: 'Name'
        type: 'String'
        physicalType: 'String'
      }
    ]
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        folderPath: 'data'
        container: 'container'
      }
      columnDelimiter: ';'
      escapeChar: '\\'
      firstRowAsHeader: true
      quoteChar: '"'
    }
  }
  dependsOn: [
    adf
    adfLsBlob
  ]
}

resource adfDatasetSqlTable 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${adf.name}/${dsSqlTable}'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: {
      referenceName: lsSqlDb
      type: 'LinkedServiceReference'
    }
    schema: [
      {
          name: 'ID'
          type: 'int'
          precision: 10
      }
      {
          name: 'Name'
          type: 'varchar'
      }
    ]
    typeProperties: {
      schema: 'test'
      table: 'Numbers'
    }
  }
  dependsOn: [
    adf
    adfLsSqlDb
  ]
}

resource adfPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${adf.name}/${pipeline}'
  properties: {
    activities: [
      {
        name: 'activityCopy'
        type: 'Copy'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        typeProperties: {
          source: {
            type: 'DelimitedTextSource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
              wildcardFolderPath: 'data'
              wildcardFileName: '*.csv'
            }
            formatSettings: {
              type: 'DelimitedTextReadSettings'
              skipLineCount: 0
            }
          }
          sink: {
            type: 'AzureSqlSink'
            writeBehavior: 'insert'
          }
          translator: {
            type: 'TabularTranslator'
            mappings: [
              {
                source: {
                  name: 'ID'
                  type: 'String'
                  physicalType: 'String'
                }
                sink: {
                  name: 'ID'
                  type: 'Int32'
                  physicalType: 'int'
                }
              }
              {
                source: {
                  name: 'Name'
                  type: 'String'
                  physicalType: 'String'
                }
                sink: {
                  name: 'Name'
                  type: 'String'
                  physicalType: 'varchar'
                }
              }
            ]
            typeConversion: true
            typeConversionSettings: {
              allowDataTruncation: true
              treatBooleanAsNumber: false
            }
          }
        }
        inputs: [
          {
            referenceName: dsBlob
            type: 'DatasetReference'
            parameters: {}
          }
        ]
        outputs: [
          {
            referenceName: dsSqlTable
            type: 'DatasetReference'
            parameters: {}
          }
        ]
      }
    ]
  }
  dependsOn: [
    adf
    adfDatasetBlob
    adfDatasetSqlTable
  ]
}
