#!/bin/bash

# check it is installed and view the version
az --version

# login
az login

# show subscriptions
az account list

# show currently selected subscription
az account show

# select subscription by id
az account set -s "fbdcf71e-154e-4a57-96ac-9b0c3267f3ce"

# or use the name
az account set -s "MVP (VS Enterprise)"

## DEMO 2 - Getting help

# getting help: view list of subscommands
az

# see the help for a subscommand:
az webapp

# get help on a subcommamd
az webapp create -h

# use the interactive console
az interactive

## DEMO 3 - using the output

# default JSON output
az webapp list

# table output
az webapp list -o table

# tsv output
az webapp list -o tsv

# color json!
az webapp list -o jsonc

## DEMO 4 - query strings
az functionapp show -n whosplayingfuncs -g whosplayingfuncs

# get one property
az functionapp show -n whosplayingfuncs -g whosplayingfuncs --query state

# two properties
az functionapp show -n whosplayingfuncs -g whosplayingfuncs --query "[state,ftpPublishingUrl]"
az functionapp show -n whosplayingfuncs -g whosplayingfuncs --query "{State:state,Ftp:ftpPublishingUrl}"

# filtering arrays - doesn't work
az functionapp list --query state
az functionapp list --query "[].state"
az functionapp list --query "[].{Name:name,Group:resourceGroup,State:state}"
az functionapp list --query "[0].{Name:name,Group:resourceGroup,State:state}"

az functionapp config appsettings list -n whosplayingfuncs -g whosplayingfuncs
az functionapp config appsettings list -n whosplayingfuncs -g whosplayingfuncs --query "[?name=='FUNCTIONS_EXTENSION_VERSION']"
az functionapp config appsettings list -n whosplayingfuncs -g whosplayingfuncs --query "[?name=='FUNCTIONS_EXTENSION_VERSION'].value"
az functionapp config appsettings list -n whosplayingfuncs -g whosplayingfuncs --query "[?name=='FUNCTIONS_EXTENSION_VERSION'].value" -o tsv

az network public-ip show -n mypublicip -g myresourcegroup --query ipAddress -o tsv
az keyvault secret show --vault-name mykeyvault --name mysecretname --query value -o tsv
az network lb show -n myloadbalancer -g myresourcegroup --query "inboundNatRules[].frontendPort" -o tsv
