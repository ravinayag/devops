## Windows 10 Multi-NIC Teaming based on NIC speed card and assign static IP address from current  
```
### Nicscript.ps1
### Gathering IP information
#$ipm = "10.120.50\."
#$DNS=10.76.32.111,10.76.32.112

$ipm = Read-Host -Prompt 'Input the network IP address with three octects without quotes [ex : "1.2.3\."] '
$DNS1 = Read-Host -Prompt 'Provide First DNS IP Address without quotes [ex : "1.2.3.4"]' 
$DNS2 = Read-Host -Prompt 'Provide First DNS IP Address without quotes [ex : "1.2.3.5"]' 
$wmi = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Where-Object { $_.IPAddress -match $ipm }
$IPAddress = $wmi.IpAddress[0]
$DefaultGateway = $wmi.DefaultIPGateway[0]
$AllNic = Get-NetAdapter |where{$_.Status -eq "Up" -or $_.Status -eq 'Disconnected'}|sort-object MacAddress

### Gathering NIC Speed 
$All10GAdapters = (Get-NetAdapter |where{$_.LinkSpeed -eq "10 Gbps" -and $_.InterfaceDesription -notmatch 'Hyper-V*' -and $_.Status -eq "Up" }|sort-object MacAddress)
$All25GAdapters = (Get-NetAdapter |where{$_.LinkSpeed -eq "25 Gbps" -and $_.InterfaceDesription -notmatch 'Hyper-V*' -and $_.Status -eq "Up" }|sort-object MacAddress)
$All40GAdapters = (Get-NetAdapter |where{$_.LinkSpeed -eq "40 Gbps" -and $_.InterfaceDesription -notmatch 'Hyper-V*' -and $_.Status -eq "Up" }|sort-object MacAddress)
$All100GAdapters = (Get-NetAdapter |where{$_.LinkSpeed -eq "100 Gbps" -and $_.InterfaceDesription -notmatch 'Hyper-V*' -and $_.Status -eq "Up" }|sort-object MacAddress)
echo $AllNic
echo " "
echo " "
echo "### Renaming the NIC interfaces as per Speed..... "
echo " "
echo " "
Start-Sleep -s 5


### Renaming NIC interfaces based on Speed
$i=0
$All10GAdapters | ForEach-Object {
    Rename-NetAdapter -Name $_.Name -NewName "Ethernet_10g_$i"
    $i++
    }
$i=0
$All25GAdapters | ForEach-Object {
    Rename-NetAdapter -Name $_.Name -NewName "Ethernet_25g_$i"
    $i++
    }
$i=0
$All40GAdapters | ForEach-Object {
    Rename-NetAdapter -Name $_.Name -NewName "Ethernet_40g_$i"
    $i++
    }
$i=0
$All100GAdapters | ForEach-Object {
    Rename-NetAdapter -Name $_.Name -NewName "Ethernet_100g_$i"
    $i++
    }

Get-NetAdapter |where{$_.Status -eq "Up" -or $_.Status -eq 'Disconnected'}|sort-object MacAddress
#### Teaming NIC based on their Speed
# Default All nics to  be in bonding on specific Speed group

#New-NetLbfoTeam -Name TEAM10G -TeamMembers Ethernet_10g_* -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false
#New-NetLbfoTeam -Name TEAM25G -TeamMembers Ethernet_25g_* -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false
#New-NetLbfoTeam -Name TEAM40G -TeamMembers Ethernet_40g_* -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false
#New-NetLbfoTeam -Name TEAM100G -TeamMembers Ethernet_100g_* -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false

##Teaming with 2 interfaces ### Custom change , if need to change nics #

$speednic = Read-Host -Prompt '[provide the  name for the Teaming/Bonding [ex : "TEAN25G"] #'
$fnic = Read-Host -Prompt 'Input the first NIC digit without quotes [ex: "0"] #'
$snic = Read-Host -Prompt 'Input the second NIC digit without quotes [ex: "1"] #'

New-NetLbfoTeam -Name $speednic -TeamMembers "Ethernet_25g_$fnic","Ethernet_25g_$snic" -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false
Start-Sleep -s 20

New-NetIPAddress –InterfaceAlias $speednic –IPAddress $IPAddress –PrefixLength 24 -DefaultGateway $DefaultGateway
Set-DnsClientServerAddress -InterfaceAlias $speednic -ServerAddresses $DNS1, $DNS2



```
