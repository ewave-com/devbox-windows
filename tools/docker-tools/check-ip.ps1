$SEL = Select-String -Path .env -Pattern "MACHINE_IP_ADDRESS" | Select-Object -ExpandProperty Line
if ($SEL -ne $null)
{
    $var = ($SEL).Split('=')
    $confMachineIp = $var[1]
}
echo "Ip From Config File :" $confMachineIp
#$ip=get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.Ipaddress.length -gt 1}
#$sysMachineIp=$ip.ipaddress[0]
$ipN = Get-NetAdapter | ? status -eq 'up' | Get-NetIPAddress -ea 0 -AddressFamily IPv4 -AddressState Preferred -PolicyStore ActiveStore -PrefixOrigin Dhcp, Manual -InterfaceAlias "Ethernet*"
$sysMachineIp = $ipN.IPAddress
echo "Ip From System :" $sysMachineIp

if ($confMachineIp -eq $sysMachineIp) {
  echo "All good, configs the same"
} else {
  echo '';

  $caption = "Looks like Ethernet IP address is not the same to Ip address set in .env file."
  $message = "Are you Sure You Want To Proceed:"
  [int]$defaultChoice = 0
  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Do the job."
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not do the job."
  $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
  $choiceRTN = $host.ui.PromptForChoice($caption,$message, $options,$defaultChoice)

  if ( $choiceRTN -ne 1 )
  {
     "continue setup process..."
  }
  else
  {
     throw "ReCheck DevBox configuration file : /.env. DevBox has been stopped"
  }
}