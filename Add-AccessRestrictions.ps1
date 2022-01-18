# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

<#
  .SYNOPSIS
  Set the access restriction of all app services in the given resource group to the rules in the 
  given JSON file.

  .DESCRIPTION
  Set the access restriction of all app services in the given resource group to the rules in the 
  given JSON file.

  .PARAMETER ResourceGroupName
  The resource group that contains the API management service and the app services to add the access restrictions to

  .PARAMETER JsonFilename
  The name of the JSON file that contains the rules and ip addresses to add to the access restriction

  .PARAMETER RemoveExistingRules
  Wether to remove all the existing access restrictions before adding the new ones

  .PARAMETER AppServicesToExclude
  A comma separated list of app services names that should be excluded

  .INPUTS
  None. You cannot pipe objects to Add-AllAccessRestrictions.ps1.

  .OUTPUTS
  None. Add-AccessRestrictions.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Add-AccessRestrictions.ps1 -ResourceGroupName resourceGroup

  .EXAMPLE
  PS> .\Add-AccessRestrictions.ps1 -ResourceGroupName resourceGroup -RemoveExistingRules $True

#>
Param(
  [Parameter(Mandatory=$True)]
  [String] $ResourceGroupName,
  [Parameter(Mandatory=$True)]
  [String] $JsonFilename,
  [Parameter(Mandatory=$False)]
  [Boolean] $RemoveExistingRules = $False,
  [Parameter(Mandatory=$False)]
  [String] $AppServicesToExclude
)

Import-Module .\Manage-AccessRestrictions.psm1

Write-Output "--> Starting access restriction script"
LoginToAzure
AddAccessRestrictionsToAppServices -ResourceGroupName $ResourceGroupName -JsonFilename $JsonFilename -RemoveExistingRules $RemoveExistingRules  -AppServicesToExclude $AppServicesToExclude
Write-Output "<-- Finished access restriction script"