Function CreateGroup{
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew() 

    $D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $setDC = $D.PdcRoleOwner
    $dnsroot = $D.Name
    $dn = ([adsi]'').distinguishedName
    Write-Host "1: " + $elapsed.Elapsed.ToString()    
    #=======================================================================
    #P1
    #set owner and creator here
    
        #p1
      
        $Domain = [ADSI]"LDAP://$($D.name)/$dn"
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
        $Searcher.SizeLimit= 100
        $Searcher.SearchRoot = "LDAP://$($D.name)/$dn"
        $Searcher.CacheResults = $true
        $Results = $Searcher.FindAll()
         Write-Host "2: " + $elapsed.Elapsed.ToString()
        #$userlist = get-aduser -ResultSetSize 2500 -Server $setdc -Filter *
        $ownerinfo = $Results | get-random
        
        $adminID = ($Results | get-random).Properties.distinguishedname | Out-String
            
    #=======================================================================
    $dn = $ownerinfo.Properties.distinguishedname
    
    
    $Description = 'Follow Davidprowe on twitter for updates to this script'
     Write-Host "3: " + $elapsed.Elapsed.ToString()
    #================================
    # OU LOCATION
    #================================
    #$OUsAll = get-adobject -Filter {objectclass -eq 'organizationalunit'} -ResultSetSize 300
    #will work on adding objects to containers later $ousall += get-adobject -Filter {objectclass -eq 'container'} -ResultSetSize 300|where-object -Property objectclass -eq 'container'|where-object -Property distinguishedname -notlike "*}*"|where-object -Property distinguishedname -notlike  "*DomainUpdates*"
    $info = ([adsisearcher]"objectclass=organizationalunit")
    $info.PropertiesToLoad.AddRange("distinguishedname")
    $OUsAll = $info.findall() | %{ $_.Properties.distinguishedname}
    $ouLocation = $OUsAll | Get-Random
     Write-Host "1: " + $elapsed.Elapsed.ToString()
    #==========================================
    #END OU WORKFLOW
    
    $Groupnameprefix = ''
    $Groupnameprefix = ($ownerinfo.Properties.samaccountname).substring(0,2)
    function Get-ScriptDirectory {
        Split-Path -Parent $PSCommandPath
    }
    $groupscriptPath = Get-ScriptDirectory
           
    $application = try{(get-content($groupscriptPath + '\hotmail.txt')|get-random).substring(0,9)} catch{(get-content($groupscriptPath + '\hotmail.txt')|get-random).substring(0,3) }
    $functionint = 1..100|Get-random  
    if($functionint -le 25){$function = 'admingroup'}else{$function = 'distlist'}              
    $GroupNameFull = $Groupnameprefix + '-'+$Application+ '-'+$Function
                                            
     Write-Host "1: " + $elapsed.Elapsed.ToString()
    $departmentnumber = [convert]::ToInt32('9999999')
       
    #Append name if duplicate name created
    $i = 1
    do {
        $checkAcct = $null
        
        if($i -gt 1)
            {
            $GroupNameFull = $GroupNameFull + $i
            }
        $i++
        try{
           $Searcher.Filter = "(&(objectCategory=person)(objectClass=user)(SamAccountName=$GroupNameFull))"
           $Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName
           $Searcher.PropertiesToLoad('distinguishedname')
           $Results = $Searcher.FindAll()
           if($Results.count -gt 0){
              $checkAcct = $Results | Select -first 1
           }
        }
        catch{}
    
        }    while($checkAcct -ne $null)
    
    $GroupType = @{
      Global      = 0x00000002
      DomainLocal = 0x00000004
      Universal   = 0x00000008
      Security    = 0x80000000
    }
    
    #=============================================
    #ATTEMPTING TO CREATE GROUP
    #=============================================
    try{
      [adsi]$OU = "LDAP://$ouLocation"
      $new = $OU.Create("Group","CN=$GroupNameFull")
      $new.CommitChanges()
      $new.put("Description",$Description)
      $new.put("grouptype",($GroupType.Security -bor $GroupType.Global))
      $new.put("samaccountname",$GroupNameFull)
      $new.put("managedBy",$adminID)
      $new.CommitChanges()

      #New-ADGroup -Server $setdc -Description $Description -Name $GroupNameFull -Path $ouLocation -GroupCategory Security -GroupScope Global -ManagedBy $ownerinfo.distinguishedname}
    }catch{    }
        
    #===============================
    #SET ATTRIBUTES
    #===============================
    
   # try{
    #    if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
     #      {write-host "Attempting to create account line 1050  "}
      #  $results = Get-adgroup $GroupNameFull -server $setdc
    
     #   }
    #catch {
        #write-host Group $name was not created:
        #write-host "`t`t`tNew-ADGroup -Server $setdc -Description $Description -Name $GroupNameFull -Path $ouLocation  -GroupCategory Security -GroupScope Global -ManagedBy $ownerinfo.distinguishedname"
     #   }
    
      
    
    
    
    }
