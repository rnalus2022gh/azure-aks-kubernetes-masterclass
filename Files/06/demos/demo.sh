
# create a resource group
resourceGroup="armtest"
location="westeurope"
az group create -l $location -n $resourceGroup

# the template we will deploy
templateUri="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/docker-wordpress-mysql/azuredeploy.json"

# deploy, specifying all template parameters directly
az group deployment create \
    --name TestDeployment \
    --resource-group $resourceGroup \
    --template-uri $templateUri \
    --parameters 'newStorageAccountName=myvhds96' \
                 'mysqlPassword=My5q1P@s5w0rd!' \
                 'adminUsername=mheath' \
                 'adminPassword=Adm1nP@s5w0rd!' \
                 'dnsNameForPublicIP=mypublicip72'

# see what's in the group we just created
az resource list -g $resourceGroup -o table

# find out the domain name we can access this from
az network public-ip list -g $resourceGroup --query "[0].dnsSettings.fqdn" -o tsv

# browse to mypublicip72.westeurope.cloudapp.azure.com

# if it doesn't work, SSH in:
ssh mheath@mypublicip72.westeurope.cloudapp.azure.com

# see if the wordpress container has exited
docker ps --all

# check the logs wordpress container
docker logs e03

# restart the wordpress container
docker start e03


# demo 2 exporting a template from a resource group (may fail due to bug in current CLI)
az group export -n CliWebAppDemo

# demo 3 - incremental deployments

# create our resource group
resourceGroup="templatedeploytest"
az group create -n $resourceGroup -l westeurope

# to validate the template
az group deployment validate -g $resourceGroup \
        --template-file MySite.json \
        --parameters @MySite.parameters.json

# perform the initial deployment
deploymentName="MyDeployment"
sqlPassword='!P@s5w0rd123'
az group deployment create -g $resourceGroup -n $deploymentName \
        --template-file MySite.json \
        --parameters @MySite.parameters.json \
        --parameters "administratorLoginPassword=$sqlPassword"
# n.b. if this fails, it is often just the Git sync - just trigger a resync


# see the web apps that got created
az webapp list -g $resourceGroup \
        --query "[].defaultHostName" -o tsv

# deploy an updated version of the template with incremental mode 
# (creates new resources only, does not delete)
az group deployment create -g $resourceGroup -n $deploymentName \
        --template-file MySiteV2.json \
        --parameters @MySite.parameters.json \
        --parameters "administratorLoginPassword=$sqlPassword" \
        --mode Incremental

# see the web apps that got created (should be two this time)
az webapp list -g $resourceGroup \
        --query "[].defaultHostName" -o tsv

# deploy the original template again in complete mode
# (will cause the additional webapp in V2 template to be deleted)
az group deployment create -g $resourceGroup -n $deploymentName \
        --template-file MySite.json \
        --parameters @MySite.parameters.json \
        --parameters "administratorLoginPassword=$sqlPassword" \
        --mode Complete

# check that there is now only one web app in the resource group again
az webapp list -g $resourceGroup \
        --query "[].defaultHostName" -o tsv

