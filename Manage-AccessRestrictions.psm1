function Add-AccessRestrictionsToAppServices([string] $ResourceGroupName, 
  [string] $JsonFilename, 
  [bool] $RemoveExistingRules, 
  [string[]] $AppServicesToExclude)
{
  Write-Information "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName

  $confirmAppServicesToExclude = Confirm-AppServicesToExclude -AllAppServices $allAppServices -AppServicesToExclude $AppServicesToExclude
  if (!$confirmAppServicesToExclude)
  {
    $errorMessage = "Did not find one or more of the app services in the exclude list, make sure that the names are spelled correctly" 
    Write-Output $errorMessage 
    throw $errorMessage
  }
  
  Write-Information "Reading the json file with ip rules"
  $ipRules = ReadJsonFile($JsonFilename)

  :nextAppService Foreach ($appService in $allAppServices)
  {
    $appServiceName = $appService.Name

    Foreach ($appServiceToExclude in $AppServicesToExclude)
    {
      if($appServiceToExclude.ToLower().Contains($appServiceName.ToLower()))
      {
        Write-Output "Skipped app service $appServiceName as it is in the exclude list"
        continue nextAppService
      }
    }

    if ($RemoveExistingRules)
    {
      Remove-AccessRestrictionsFromAppService -ResourceGroupName $ResourceGroupName -Name $appServiceName          
    }

    Foreach ($ipRule in $ipRules)
    {
      # Construct ip address filter for access restriction /32 = single ip address
      $ipAddress = -join($ipRule.ipaddress, "/32");
      Add-AccessRestrictionToAppService -ResourceGroupName $ResourceGroupName -Name $appServiceName  -IpFilterRuleName $ipRule.rulename -IpAddress $ipAddress -Priority $ipRule.priority
    }
  }
}

function Confirm-AppServicesToExclude([Object[]] $AllAppServices, [string[]] $AppServicesToExclude)
{
  if ($AppServicesToExclude.Length -gt 0)
  {
    Foreach ($appServiceToExclude in $AppServicesToExclude)
    {
      $appServiceExist = $AllAppServices | Where-Object { $_.Name -eq $appServiceToExclude }
      if (!$appServiceExist)
      {
        Write-Information "Could not find $appServiceToExclude in the list of app services"
        return $false
      }
    }
  }
  return $true
}

function Remove-AllAccessRestrictionsFromAppServices([string] $ResourceGroupName)
{
  Write-Information "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
  Foreach ($appService in $allAppServices)
  {
    Remove-AccessRestrictionsFromAppService -ResourceGroupName $ResourceGroupName -Name $appService.Name
  }
}

function Remove-AccessRestrictionsFromAppService([string] $ResourceGroupName, [string] $Name)
{
  $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $Name
  Write-Information "Removing existing access restrictions on $Name"
  Foreach ($accessRestriction in $config.MainSiteAccessRestrictions)
  {
    $ruleName = $accessRestriction.RuleName
    Write-Debug "Removing rule $ruleName"
    Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Name $accessRestriction.RuleName
  }

  # Also remove all the access restriction from the staging slots
  $allSlots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $Name
  Foreach ($slot in $allSlots)
  {
    $slotName = Get-SlotName -SlotName $slot.Name -AppServiceName $Name
    Write-Information "Removing existing access restrictions on $Name slot $slotName"
    $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $Name -SlotName $slotName
    Foreach ($accessRestriction in $config.MainSiteAccessRestrictions)
    {
      $ruleName = $accessRestriction.RuleName
      Write-Debug "Removing rule $ruleName"
      Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Name $accessRestriction.RuleName -SlotName $slotName
    }
  }
}

function Add-AccessRestrictionToAppService([string] $ResourceGroupName, [string] $Name, [string] $IpFilterRuleName, [string] $IpAddress, [string] $Priority)
{
  Write-Information "Adding rule $IpFilterRuleName to allow api management service with ip $IpAddress and $Priority access to $Name"
  Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Name $IpFilterRuleName -Priority $Priority -Action Allow -IpAddress $IpAddress
  Update-AzWebAppAccessRestrictionConfig -Name $appService.Name -ResourceGroupName $ResourceGroupName -ScmSiteUseMainSiteRestrictionConfig

  # Also add the access restriction to the staging slots
  $allSlots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $Name
  Foreach ($slot in $allSlots)
  {
    $slotName = Get-SlotName -SlotName $slot.Name -AppServiceName $Name
    Write-Information "Adding rule $IpFilterRuleName to allow api management service with ip $IpAddress and priority $Priority access to $Name slot $slotName"
    Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Slot $slotName -Name $IpFilterRuleName -Priority $Priority -Action Allow -IpAddress $IpAddress
    Update-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $Name -Slot $slotName -ScmSiteUseMainSiteRestrictionConfig
  }
}

function Get-SlotName([string] $SlotName, [string] $AppServiceName)
{
  return $SlotName.Replace("$($AppServiceName)/", "")
}

function ReadJsonFile([string] $JsonFile)
{
  if (Test-Path -Path $JsonFile -PathType Leaf)
  {
    $rules = Get-Content -Raw -Path ./ip-addresses.json | ConvertFrom-Json
    return $rules
  } else
  {
    Write-Output "The given file $JsonFile does not exist."
  }
}

function LoginToAzure()
{
  Write-Output "Logging in..."
  Connect-AzAccount -ErrorAction Stop
  Write-Output "Successfuly logged in"
}

Export-Modulemember -Function LoginToAzure
Export-Modulemember -Function Remove-AccessRestrictionsFromAppServices
Export-Modulemember -Function Add-AccessRestrictionsToAppServices