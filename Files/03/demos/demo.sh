# DEMO 1 - exploring images

# see the VM sub-options
az vm -h

# show the most commonly used ones
az vm image list -o table

# search all images for specific "offer"
az vm image list --all -f elasticsearch -o table #also try VisualStudio, Wordpress

# search all images for a specific "sku"
az vm image list -s VS-2017 --all -o table

# see all the vm sizes available in a specific location
az vm list-sizes --location westeurope -o table

# DEMO 2 - Creating the VM

ResourceGroupName="CreateVmDemo"

az group create --name $ResourceGroupName --location westeurope

az vm create -h | more

VmName="ExampleVm"
AdminPassword="P1ur@15ight!"

az vm create \
    --resource-group $ResourceGroupName \
    --name $VmName \
    --image win2016datacenter \
    --admin-username azureuser \
    --admin-password $AdminPassword
    # money saving tips:
    # --size Basic_A1
    # --use-unmanaged-disk
    # --storage-sku Standard_LRS

# see what's in the group
az resource list -g $ResourceGroupName -o table

# see what size VM it created for us
az vm show -g $ResourceGroupName -n $VmName --query "hardwareProfile.vmSize"

# DEMO 3 - updating the VM

# remind ourselves what the public ip was
az vm list-ip-addresses -n $VmName -g $ResourceGroupName -o table

# open port 80
az vm open-port --port 80 --resource-group $ResourceGroupName --name $VmName

# install IIS with a custom Powershell script
az vm extension set \
--publisher Microsoft.Compute \
--version 1.8 \
--name CustomScriptExtension \
--vm-name $VmName \
--resource-group $ResourceGroupName \
--settings extensionSettings.json


# DEMO 4 - stopping

# see available commands for stopping and starting VMs
az vm -h

# see what state it is in - it's running
az vm show -d -g $ResourceGroupName -n $VmName --query "powerState" -o tsv

# stop and deallocate so we no longer pay for resources
az vm deallocate -n $VmName -g $ResourceGroupName

# check its stopped
az vm show -d -g $ResourceGroupName -n $VmName --query "powerState" -o tsv

# lets start it back up again
az vm start -n $VmName -g $ResourceGroupName

# another way to get the public ip
az vm show -d -g $ResourceGroupName -n $VmName --query "publicIps" -o tsv

# remind ourselves what is in the group
az resource list -g $ResourceGroupName -o table

# delete the whole resource group
az group delete --name $ResourceGroupName --yes


