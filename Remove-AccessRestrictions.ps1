<#
  .SYNOPSIS
  Remove all access restrictions from the app services in the given resource group

  .DESCRIPTION
  The Remove-AccessRestrictions.ps1 script removes all access restrictions from the app services in the given resource group

  .PARAMETER resourceGroupName
  The resource group with the app services to remove the access restrictions

  .INPUTS
  None. You cannot pipe objects to Remove-AccessRestrictions.ps1.

  .OUTPUTS
  None. Remove-AllAccessRestrictions.ps1 does not generate any output.

  .EXAMPLE
  PS> .\Remove-AllAccessRestrictions.ps1 -ResourceGroupName resourceGroup
#>

Param(
  [Parameter(Mandatory=$True)]
  [String] $resourceGroupName
)

Import-Module .\Manage-AccessRestrictions.psm1

Write-Output "--> Starting remove all access restriction script"
LoginToAzure
RemoveAccessRestrictionsOnAppServices -ResourceGroupName $resourceGroupName
Write-Output "<-- Finished remove all access restriction script"