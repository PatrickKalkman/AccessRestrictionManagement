function AddAccessRestrictionsToAppServices([string] $ResourceGroupName, 
  [string] $JsonFilename, 
  [bool] $RemoveExistingRules, 
  [string] $AppServicesToExclude)
{
  Write-Output "Reading the json file with ip rules"
  $ipRules = ReadJsonFile($JsonFilename)

  Write-Output "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
  Foreach ($appService in $allAppServices)
  {
    $appServiceName = $appService.Name

    if($AppServicesToExclude.ToLower().Contains($appServiceName.ToLower()))
    {
      Write-Output "Skipped app service $appServiceName as it is in the exclude list"
      continue
    }

    if ($RemoveExistingRules)
    {
      $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $appService.Name
      Write-Output "Removing existing access restrictions on $appServiceName"
      Foreach ($accessRestriction in $config.MainSiteAccessRestrictions)
      {
        Write-Information "Removing rule $accessRestriction.RuleName"
        Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $appService.Name -Name $accessRestriction.RuleName
      }
    }

    Foreach ($ipRule in $ipRules)
    {
      $ruleName = $ipRule.rulename
      $ipAddress = $ipRule.ipaddress
      Write-Output "Adding rule $ruleName to allow ip $ipAddress access to $appServiceName"
    
      # Construct ip address filter for access restriction /32 = single ip address
      $ipAddress = -join($ipRule.ipaddress, "/32");
      Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $appService.Name -Name $ipRule.rulename -Priority 200 -Action Allow -IpAddress $ipAddress
      # Set the ipfilter also on the scm site
      Update-AzWebAppAccessRestrictionConfig -Name $appService.Name -ResourceGroupName $ResourceGroupName -ScmSiteUseMainSiteRestrictionConfig
    }
  }
}

function RemoveAccessRestrictionsOnAppServices([string] $ResourceGroupName)
{
  Write-Output "Retrieving all app services in $ResourceGroupName"
  $allAppServices = Get-AzWebApp -ResourceGroupName $ResourceGroupName
  Foreach ($appService in $allAppServices)
  {
    $appServiceName = $appService.Name
    $config = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $appService.Name
    Write-Output "Removing existing access restrictions on $appServiceName"

    Foreach ($accessRestriction in $config.MainSiteAccessRestrictions)
    {
      $ruleName = $accessRestriction.RuleName
      Write-Information "Removing rule $ruleName"
      Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $appService.Name -Name $accessRestriction.RuleName
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
Export-Modulemember -Function RemoveAccessRestrictionsOnAppServices
Export-Modulemember -Function AddAccessRestrictionsToAppServices