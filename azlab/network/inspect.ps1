#!/usr/bin/pwsh 

$rg = 'psg_networklab20190916'
$vnetname = 'ERP-servers'
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


ssh azureuser@$APPSERVERIP -o ConnectTimeout=5

ssh azureuser@$DATASERVERIP -o ConnectTimeout=5







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

