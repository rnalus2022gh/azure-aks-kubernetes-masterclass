# select correct subscription with 
az account set -s "my subscription name"

# a name for our azure ad app
appName="ServicePrincipalDemo1"

# create an Azure AD app
az ad app create \
    --display-name $appName \
    --homepage "http://localhost/$appName" \
    --identifier-uris "http://localhost/$appName"

# get the app id
appId=$(az ad app list --display-name $appName --query [].appId -o tsv)

# choose a password for our service principal
spPassword="My5erv1c3Pr1ncip@l1!"

# create a service principal
az ad sp create-for-rbac --name $appId --password $spPassword 

# get the app id of the service principal
servicePrincipalAppId=$(az ad sp list --display-name $appId --query "[].appId" -o tsv)

# view the default role assignment (it will be contributor access to the whole subscription)
az role assignment list --assignee $servicePrincipalAppId

# get the id of that default assignment
roleId=$(az role assignment list --assignee $servicePrincipalAppId --query "[].id" -o tsv)

# delete that role assignment
az role assignment delete --ids $roleId

# make a resource group that we will allow our service principal contributor rights to
resourceGroup="MyVmDemo"
az group create -n $resourceGroup -l westeurope

# get our subscriptionId
subscriptionId=$(az account show --query id -o tsv)

# grant contributor access just to this resource group only
az role assignment create --assignee $servicePrincipalAppId \
        --role "contributor" \
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup"

# n.b to see this assignment, you neeed the --all flag:
az role assignment list --assignee $servicePrincipalAppId --all

# get the tenant id
tenantId=$(az account show --query tenantId -o tsv)

# now let's logout
az logout

# and log back in with the service principal
az login --service-principal -u $servicePrincipalAppId \
         --password $spPassword --tenant $tenantId

# what groups can we see? should be just one:
az group list -o table

# can we create a new resource group? should be denied:
az group create -n NotAllowed -l westeurope

# but we should be able to create a VM:
vmName="ExampleVm"
adminPassword="ARe@11y5ecur3P@ssw0rd!"

az vm create \
    --resource-group $resourceGroup \
    --name $vmName \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $adminPassword \
    --size Basic_A1 \
    --use-unmanaged-disk \
    --storage-sku Standard_LRS

# check its running state
az vm show -d -g $resourceGroup -n $vmName --query "powerState" -o tsv

# cleaning up - log out and log back in again with regular credentials
az logout
az login

# delete the service principal
az ad sp delete --id $servicePrincipalAppId

# delete the ad app
az ad app delete --id $appId

# delete the resource group with our test VM
az group delete -n $resourceGroup --yes


# providing the credentials to a functionapp
functionappName="markfunctionapp"
functionappGroup="AzureFunctions-WestEurope"
az functionapp config appsettings set -n $functionappName -g $functionappGroup \
--settings "SERVICE_PRINCIPAL=$servicePrincipalAppId"  \
"SERVICE_PRINCIPAL_SECRET=$spPassword" "TENANT_ID=$tenantId"