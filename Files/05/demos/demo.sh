# DEMO 1 Create an app service plan and web app

# Reminder: log in with az login
# Reminder: choose subscription with az account set -s "Subscription name or GUID"

# set up some variables
resourceGroup="CliWebAppDemo"
location="westeurope"

# create a resource group
az group create -n $resourceGroup -l $location

# see the options for creating an app service plan
az appservice plan create -h

# create the app service plan
planName="CliWebAppDemo"
az appservice plan create -n $planName -g $resourceGroup --sku B1

# create the webapp
appName="pluralsightclidemo"
az webapp create -n $appName -g $resourceGroup --plan $planName

# discover the URI
az webapp show -n $appName -g $resourceGroup --query "defaultHostName"

# DEMO 2 Configure git deployment
gitrepo="https://github.com/markheath/azure-cli-snippets"

# configure the app to deploy from a GitHub repo
az webapp deployment source config -n $appName -g $resourceGroup \
    --repo-url $gitrepo --branch master --manual-integration

# request a sync
az webapp deployment source sync -n $appName -g $resourceGroup

# DEMO 3 create a SQL server and database

sqlServerName="pluralsightclidemo"
sqlServerUsername="mheath"
sqlServerPassword='!SecureP@assword1'

# create the SQL server
az sql server create -n $sqlServerName -g $resourceGroup \
            -l $location -u $sqlServerUsername -p $sqlServerPassword

databaseName="SnippetsDatabase"

# discover available editions
az sql db list-editions -l $location -o table

# create the database
az sql db create -g $resourceGroup -s $sqlServerName -n $databaseName \
          --service-objective Basic

# DEMO 4 Connect SQL server to web app

# see the outbound IP addresses our web app is using
az webapp show -n $appName -g $resourceGroup --query "outboundIpAddresses" \
               -o tsv

# allow the special 0.0.0.0 ip address access to SQL server ()
az sql server firewall-rule create -g $resourceGroup -s $sqlServerName \
     -n AllowWebApp1 --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# construct the connection string
connectionString="Server=tcp:$sqlServerName.database.windows.net;Database=$databaseName;User ID=$sqlServerUsername@$sqlServerName;Password=$sqlServerPassword;Trusted_Connection=False;Encrypt=True;"

# provide add the connection string to the web app
az webapp config connection-string set \
    -n $appName -g $resourceGroup \
    --settings "SnippetsContext=$connectionString" \
    --connection-string-type SQLAzure

# DEMO 5 - Backup and restore the database

# get hold of the storage account connection string for the backup
storageAccount="assetswe"
storageResourceGroup="SharedAssets"
storageConnectionString=`az storage account show-connection-string -n $storageAccount -g $storageResourceGroup --query connectionString -o tsv`

# extract just the storage key
storageKey=`echo $storageConnectionString | grep -oP "AccountKey=\K.+"`

# generate a unique filename for the backup
now=$(date +"%Y-%m-%d-%H-%M")
backupFileName="backup-$now.bacpac"

# perform the database backup
az sql db export -s $sqlServerName -n $databaseName -g $resourceGroup \
-u $sqlServerUsername -p $sqlServerPassword \
--storage-key-type StorageAccessKey --storage-key $storageKey \
--storage-uri "https://$storageAccount.blob.core.windows.net/bacpacs/$backupFileName" 

# generate a new empty database
databaseName2="SnippetsDatabase2"
az sql db create -g $resourceGroup -s $sqlServerName -n $databaseName2 \
--service-objective Basic

# import the backup to a new database
az sql db import -s $sqlServerName -n $databaseName2 -g $resourceGroup \
-u $sqlServerUsername -p $sqlServerPassword \
--storage-key-type StorageAccessKey --storage-key $storageKey \
--storage-uri "https://$storageAccount.blob.core.windows.net/bacpacs/$backupFileName" 

# create a connection string for the new database
connectionString2="Server=tcp:$sqlServerName.database.windows.net;Database=$databaseName2;User ID=$sqlServerUsername@$sqlServerName;Password=$sqlServerPassword;Trusted_Connection=False;Encrypt=True;"

# update the web app to point to the new database
az webapp config connection-string set \
    -n $appName -g $resourceGroup \
    --settings "SnippetsContext=$connectionString2" \
    --connection-string-type SQLAzure
