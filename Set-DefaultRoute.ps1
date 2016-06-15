function Set-DefaultRoute {
	param (
		[bool]$IncludePrivateNetwork=$true,
		[bool]$Wired2WiFi=$true
	)
	$ErrorActionPreference = "Stop"
	cls

	If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
		[Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
		Break
	}

	$activeAdapters =@()
	$activeAdapters = Get-NetAdapter -Physical | where {($_.AdminStatus -eq 1 -and $_.InterfaceOperationalStatus -eq 1) `
		-and ($_.PhysicalMediaType -eq "Native 802.11" -or $_.PhysicalMediaType -eq "802.3")}

	if ($activeAdapters.count -lt 2) {
		Write-Warning "There's only one active adapter, therefore no route will be changed" 
		Break
	}

	$wiredInterface = $activeAdapters | Where {$_.PhysicalMediaType -eq "802.3"}
	$wirelessInterface = $activeAdapters | Where {$_.PhysicalMediaType -eq "Native 802.11"}

	$wiredGateway = Get-NetIPConfiguration -InterfaceAlias $wiredInterface.InterfaceAlias
	$wirelessGateway = Get-NetIPConfiguration -InterfaceAlias $wirelessInterface.InterfaceAlias


	if ($Wired2WiFi) {
		Remove-NetRoute -NextHop $wiredGateway.IPv4DefaultGateway.NextHop -Confirm:$false
		if ($IncludePrivateNetwork) {
			New-NetRoute -DestinationPrefix "10.0.0.0/8" -InterfaceIndex $wiredInterface.InterfaceIndex -PolicyStore ActiveStore
			New-NetRoute -DestinationPrefix "172.16.0.0/12" -InterfaceIndex $wiredInterface.InterfaceIndex -PolicyStore ActiveStore
			New-NetRoute -DestinationPrefix "192.168.0.0/16" -InterfaceIndex $wiredInterface.InterfaceIndex -PolicyStore ActiveStore 
		}
	} else {
		Remove-NetRoute -NextHop $wirelessGateway.IPv4DefaultGateway.NextHop -Confirm:$false
		if ($IncludePrivateNetwork) {
			New-NetRoute -DestinationPrefix "10.0.0.0/8" -InterfaceIndex $wirelessInterface.InterfaceIndex -PolicyStore ActiveStore 
			New-NetRoute -DestinationPrefix "172.16.0.0/12" -InterfaceIndex $wirelessInterface.InterfaceIndex -PolicyStore ActiveStore
			New-NetRoute -DestinationPrefix "192.168.0.0/16" -InterfaceIndex $wirelessInterface.InterfaceIndex -PolicyStore ActiveStore
		}
	}
}