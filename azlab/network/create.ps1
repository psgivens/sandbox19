#!/usr/bin/pwsh 

$rg = 'psg_networklab20190916'
$vnetname = 'ERP-servers'
$dbasg = 'ERP-DB-SERVERS-ASG'
$nsgname = 'ERP-SERVERS-NSG'

# TODO: Create the steps from the lab


az network nsg rule create `
    --resource-group $rg `
    --nsg-name ERP-SERVERS-NSG `
    --name httpRule `
    --direction Inbound `
    --priority 150 `
    --source-address-prefixes 10.0.1.4 `
    --source-port-ranges '*' `
    --destination-address-prefixes 10.0.0.4 `
    --destination-port-ranges 80 `
    --access Deny `
    --protocol Tcp `
    --description "Deny from DataServer to AppServer on port 80"


# Create the application security group
az network asg create `
  --resource-group $rg `
  --name $dbasg 

# Add db NICs to the ASG
az network nic ip-config update `
    --resource-group $rg `
    --application-security-groups $dbasg `
    --name ipconfigDataServer `
    --nic-name DataServerVMNic `
    --vnet-name $vnetname `
    --subnet Databases

$empty = ""

# Update the security rule to use the ASG
az network nsg rule update `
    --resource-group $rg `
    --nsg-name $nsgname `
    --name httpRule `
    --direction Inbound `
    --priority 150 `
    --source-port-ranges '*' `
    --source-asgs $dbasg `
    --source-address-prefixes '""' `
    --destination-address-prefixes 10.0.0.4 `
    --destination-port-ranges 80 `
    --access Deny `
    --protocol Tcp `
    --description "Deny from DataServer to AppServer on port 80 using application security group"



# Create security rules for storage exercise
az network nsg rule create `
    --resource-group $rg `
    --nsg-name ERP-SERVERS-NSG `
    --name Allow_Storage `
    --priority 190 `
    --direction Outbound `
    --source-address-prefixes "VirtualNetwork" `
    --source-port-ranges '*' `
    --destination-address-prefixes "Storage" `
    --destination-port-ranges '*' `
    --access Allow `
    --protocol '*' `
    --description "Allow access to Azure Storage"


az network nsg rule create `
    --resource-group $rg `
    --nsg-name ERP-SERVERS-NSG `
    --name Deny_Internet `
    --priority 200 `
    --direction Outbound `
    --source-address-prefixes "VirtualNetwork" `
    --source-port-ranges '*' `
    --destination-address-prefixes "Internet" `
    --destination-port-ranges '*' `
    --access Deny `
    --protocol '*' `
    --description "Deny access to Internet."


$STORAGEACCT=az storage account create `
                --resource-group $rg `
                --name engineeringdocs8675309 `
                --sku Standard_LRS `
                --query "name" | tr -d '"'

$STORAGEKEY = az storage account keys list `
                --resource-group $rg `
                --account-name $STORAGEACCT `
                --query "[0].value" | tr -d '"'

az storage share create `
    --account-name $STORAGEACCT `
    --account-key $STORAGEKEY `
    --name "erp-data-share"

# Enable the Service endpoint
az network vnet subnet update `
    --vnet-name ERP-servers `
    --resource-group $rg `
    --name Databases `
    --service-endpoints Microsoft.Storage

az storage account update `
    --resource-group $rg `
    --name $STORAGEACCT `
    --default-action Deny

az storage account network-rule add `
    --resource-group $rg `
    --account-name $STORAGEACCT `
    --vnet ERP-servers `
    --subnet Databases

# Test access to storage accounts
$publicip_query = "[].virtualMachine.network.publicIpAddresses[*].ipAddress" 
$APPSERVERIP = az vm list-ip-addresses `
                 --resource-group $rg `
                 --name AppServer `
                 --query $publicip_query `
                 --output tsv
$DATASERVERIP = az vm list-ip-addresses `
                 --resource-group $rg `
                 --name DataServer `
                 --query $publicip_query `
                 --output tsv

ssh -t azureuser@$APPSERVERIP `
    "mkdir azureshare; \
    sudo mount -t cifs //$STORAGEACCT.file.core.windows.net/erp-data-share azureshare \
    -o vers=3.0,username=$STORAGEACCT,password=$STORAGEKEY,dir_mode=0777,file_mode=0777,sec=ntlmssp; findmnt \
    -t cifs; exit; bash"

ssh -t azureuser@$DATASERVERIP `
    "mkdir azureshare; \
    sudo mount -t cifs //$STORAGEACCT.file.core.windows.net/erp-data-share azureshare \
    -o vers=3.0,username=$STORAGEACCT,password=$STORAGEKEY,dir_mode=0777,file_mode=0777,sec=ntlmssp;findmnt \
    -t cifs; exit; bash"









# Left over from reading the items.


$subnets = az network vnet subnet list `
  --vnet-name $vnetname `
  --resource-group $rg
$subnets

$nsg = az network nsg list `
  --resource-group $rg

$publicip_query = "[].virtualMachine.network.publicIpAddresses[*].ipAddress" 

 
$APPSERVERIP = az vm list-ip-addresses `
                 --resource-group $rg `
                 --name AppServer `
                 --query $publicip_query `
                 --output tsv


 
$DATASERVERIP = az vm list-ip-addresses `
                 --resource-group $rg `
                 --name DataServer `
                 --query $publicip_query `
                 --output tsv


ssh azureuser@$APPSERVERI -o ConnectTimeout=5







$vms = Get-AzVM

$vmsjson = az vm list 
$vms = $vmsjson | ConvertFrom-Json

$x = az vm list `
    --resource-group $rg `
    --show-details `
    --query "[*].{Name:name, PrivateIP:privateIps, PublicIP:publicIps}" 


az vm list `
    --name AppServer `
    --resource-group $rg `
    --show-details `
    --query "[*].{Name:name, PrivateIP:privateIps, PublicIP:publicIps}" 

$appvm = $vms |?{$_.Name -contains 'AppServer'}
$datvm = $vms |?{$_.Name -contains 'DataServer'}

$vms |%{"{0} {1}" -f $_.privateips, $_.publicips }

$vms |%{$_.privateIps, $_.publicips }

