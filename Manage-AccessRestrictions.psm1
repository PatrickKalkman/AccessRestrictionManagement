function Add-AccessRestrictionsToAppServices([string] $ResourceGroupName, 
  [string] $JsonFilename, 
  [bool] $RemoveExistingRules, 
  [string] $AppServicesToExclude)
{
  Write-Information "Reading the json file with ip rules"
  $ipRules = ReadJsonFile($JsonFilename)

  Write-Information "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
  Foreach ($appService in $allAppServices)
  {
    $appServiceName = $appService.Name

    if($AppServicesToExclude.ToLower().Contains($appServiceName.ToLower()))
    {
      Write-Information "Skipped app service $appServiceName as it is in the exclude list"
      continue
    }

    if ($RemoveExistingRules)
    {
      $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $appService.Name
      Write-Information "Removing existing access restrictions on $appServiceName"
      Foreach ($accessRestriction in $config.MainSiteAccessRestrictions)
      {
        Write-Debug "Removing rule $accessRestriction.RuleName"
        Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $appService.Name -Name $accessRestriction.RuleName
      }
    }

    Foreach ($ipRule in $ipRules)
    {
      $ruleName = $ipRule.rulename
      $ipAddress = $ipRule.ipaddress
      Write-Information "Adding rule $ruleName to allow ip $ipAddress access to $appServiceName"
    
      # Construct ip address filter for access restriction /32 = single ip address
      $ipAddress = -join($ipRule.ipaddress, "/32");
      Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $appService.Name -Name $ipRule.rulename -Priority 200 -Action Allow -IpAddress $ipAddress
      # Set the ipfilter also on the scm site
      Update-AzWebAppAccessRestrictionConfig -Name $appService.Name -ResourceGroupName $ResourceGroupName -ScmSiteUseMainSiteRestrictionConfig
    }
  }
}

function Remove-AllAccessRestrictionsFromAppServices([string] $ResourceGroupName) {
  Write-Information "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
  Foreach ($appService in $allAppServices) {
      Remove-AccessRestrictionsFromAppService -ResourceGroupName $ResourceGroupName -Name $appService.Name
  }
}

function Remove-AccessRestrictionsFromAppService([string] $ResourceGroupName, [string] $Name) {
  $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $Name
  Write-Information "Removing existing access restrictions on $Name"
  Foreach ($accessRestriction in $config.MainSiteAccessRestrictions) {
      $ruleName = $accessRestriction.RuleName
      Write-Debug "Removing rule $ruleName"
      Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Name $accessRestriction.RuleName
  }

  # Also remove all the access restriction from the staging slots
  $allSlots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $Name
  Foreach ($slot in $allSlots) {
      $slotName = Get-SlotName -SlotName $slot.Name -AppServiceName $Name
      Write-Information "Removing existing access restrictions on $Name slot $slotName"
      $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $Name -SlotName $slotName
      Foreach ($accessRestriction in $config.MainSiteAccessRestrictions) {
          $ruleName = $accessRestriction.RuleName
          Write-Debug "Removing rule $ruleName"
          Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $Name -Name $accessRestriction.RuleName -SlotName $slotName
      }
  }
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