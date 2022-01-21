<#
  .SYNOPSIS
  Get the ip address from the ip-addresses.json and give these access to all the 
  app services in the given resource group.  

  .DESCRIPTION
  Get the ip address from the ip-addresses.json and give these access to all the 
  app services in the given resource group.

  .PARAMETER JsonFilename
  The file name of the json file that contains the ip addresses

  .PARAMETER ResourceGroupName
  The resource group that contains the app services to add the access restrictions to

  .PARAMETER RemoveExistingRules
  Wether to first remove all the existing access restrictions before adding the new ones

  .PARAMETER AppServicesToExclude
  A comma separated list of app services names that should be excluded

  .INPUTS
  None. You cannot pipe objects to Add-AllAccessRestrictions.ps1.

  .OUTPUTS
  None. Add-AccessRestrictions.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Add-AccessRestrictions.ps1 -JsonFilename ./ip-addresses.json -ResourceGroupName MyResourceGroup

  .EXAMPLE
  PS> .\Add-AccessRestrictions.ps1 -JsonFilename ./ip-addresses.json -ResourceGroupName MyResourceGroup  -RemoveExistingRules $True

  .EXAMPLE
  PS> .\Add-AccessRestrictions.ps1 -JsonFilename ./ip-addresses.json -ResourceGroupName MyResourceGroup -RemoveExistingRules $True -AppServicesToExclude myAppServiceToExclude1, myAppServiceToExclude2

#>
Param(
  [Parameter(Mandatory=$True)]
  [String] $JsonFilename,
  [Parameter(Mandatory=$True)]
  [String] $ResourceGroupName,
  [Parameter(Mandatory=$False)]
  [Boolean] $RemoveExistingRules = $False,
  [Parameter(Mandatory=$False)]
  [String[]] $AppServicesToExclude = @()
)

Import-Module .\Manage-AccessRestrictions.psm1

Write-Output "--> Starting access restriction script"
LoginToAzure
Add-AccessRestrictionsToAppServices -JsonFilename $JsonFilename -ResourceGroupName $ResourceGroupName -RemoveExistingRules $RemoveExistingRules -AppServicesToExclude $AppServicesToExclude
Write-Output "<-- Finished access restriction script"