# make sure you have the correct subscription set up
az account set -s "My Subscription"

# store some variable
resourceGroup="CliStorageTest"
location="westeurope"
storageAccount="cliblobtest"

# create our resource group
az group create -n $resourceGroup -l $location

# get some help on creating a storage account
az storage account create -h

# create a storage account
az storage account create -n $storageAccount -g $resourceGroup -l $location --sku Standard_LRS

# get the connection string
connectionString=`az storage account show-connection-string -n $storageAccount -g $resourceGroup --query connectionString -o tsv`

echo $connectionString

# BLOBS

# learn more about az storage subgroups of commands
az storage -h

# learn more about how to create a container
az storage container create -h

# create a new container with public access
az storage container create -n "public" --public-access blob --connection-string $connectionString

# save our connection string into an environment variable to save us passing it to every commmand
export AZURE_STORAGE_CONNECTION_STRING=$connectionString
# in powershell:  $env:AZURE_STORAGE_CONNECTION_STRING = $connectionString

# create a private container
az storage container create -n "private" --public-access off

# create a demo file
echo "Hello World" > example.txt
cat example.txt

# upload the demo file to the public container
az storage blob upload -c "public" -f "example.txt" -n "test.txt"

# get the URL of the blob
az storage blob url -c "public" -n "test.txt" -o tsv

# the blob name for where we will upload it into the private container
blobName="secret/private.txt"

# upload the file into the private container with the specified name
az storage blob upload -c "private" -f "example.txt" -n $blobName

# get the URL of the blob in the private container
az storage blob url -c "private" -n $blobName -o tsv

# generate a time limited read-only shared access signature for the private blob
az storage blob generate-sas -c "private" -n $blobName \
    --permissions r -o tsv \
    --expiry 2017-10-15T13:24Z

# see more things you can do with blobs
az storage blob -h


# QUEUES

#the queue name we'll use
queueName="myqueue"

# create a new queue
az storage queue create -n $queueName

# put some messages onto the queue
az storage message put --content "Hello from CLI" -q $queueName
az storage message put --content "Hello from CLI 2" -q $queueName

# get a message and give ourselves two minutes to process it
az storage message get -q $queueName --visibility-timeout 120

# delete the message from the queue
az storage message delete --id "25b802f4-5e7e-4ecb-9a70-55a06f9c5c6c" --pop-receipt "AgAAAAMAAAAAAAAAPNz4JMVE0wE=" -q $queueName

# TABLES

# the table name we'll use
tableName="mytable"

# create the table
az storage table create -n $tableName

# insert a new row into the table
az storage entity insert -t $tableName -e PartitionKey="Settings" RowKey="Timeout" Value=10 Description="Timeout in seconds"

# and insert another row
az storage entity insert -t $tableName -e PartitionKey="Settings" RowKey="MaxRetries" Value=4 Description="Maximum Retries"

# read rows from our table without a filter
az storage entity query -t $tableName

# learn more about filters: https://docs.microsoft.com/en-us/rest/api/storageservices/Querying-Tables-and-Entities?redirectedfrom=MSDN

# query for a specific partition key
az storage entity query -t $tableName --filter "PartitionKey eq 'Settings'"

# query for a specific value in a custom column
az storage entity query -t $tableName --filter 'Value eq 10'

# replace a row with the given row and partition key
az storage entity replace -t $tableName -e PartitionKey="Settings" RowKey="MaxRetries" Value=5 Description="Maximum Retries"

# update columns in the row with the specified row and partition key
az storage entity merge -t $tableName -e PartitionKey="Settings" RowKey="MaxRetries" Value=6

# retrieve the contents of a single row
az storage entity show -t $tableName --partition-key "Settings" --row-key "MaxRetries"

# SHARES

# name of our file share
fileShare="myshare"

# create the file share with a 2GB quota
az storage share create -n $fileShare --quota 2

# upload an example file
az storage file upload -s $fileShare --source "example.txt"

# list files in the fileshare
az storage file list -s $fileShare


# learn more about what you can do with file shares
az storage file -h

# cleaning up
az group delete -n $resourceGroup --yes
