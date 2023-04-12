# IaC
## Bicep files to automate standard KiZAN Azure Data Factory deployment

`Files: KZ-main.bicep and KZ-ADF.bicep:` small, baseilne test and POC that provide a small deployment of Resource Group, Storage Account and empty ADF.

`Files main-sandbox.bicep, adf-sandbox.bicep and adf.parameters.jsonc:` add key-vault with secrets for blob storage and sql server. The ADF includes a Key Vault linked 
service to securely access data and blob linked service. Added parameter file and pass params between main and modeule.

work to continue...
