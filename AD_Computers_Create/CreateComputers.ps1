################################
#Create Computer Objects
################################
Function CreateComputer{

    param(
            
            $Owner,
            $Creator,
            $WorkstationOrServer,
            $OUlocation,
            $Make,
            $Model,
            $SN,
            $IP,
            $DNS,
            $Gateway,
            $WorkstationType,
            $ServerApplication,
            $Description,
            $debug,
            $HideResults
        )

    
    #=======================================================================
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    $D = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $setDC = $D.PdcRoleOwner
    $dnsroot = $D.Name
   # $userlist = get-adobject -Filter {objectclass -eq 'user'} -ResultSetSize 2500 -Server $setdc|Where-object -Property objectclass -eq user
    function Get-ScriptDirectory {
        Split-Path -Parent $PSCommandPath
    }
    $scriptPath = Get-ScriptDirectory
    $scriptparent = (get-item $scriptpath).parent.fullname
    $3lettercodes = import-csv ($scriptparent + "\AD_OU_CreateStructure\3lettercodes.csv")
    #=======================================================================
    $dn = ($D.GetDirectoryEntry()).distinguishedname
    $Domain = [ADSI]"LDAP://$D"
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher
    $Searcher.Filter = "(&(objectClass=organizationalUnit))"
    $Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName
    $Results = $Searcher.FindAll()
    $OUsAll = $Results | %{ $_.Properties.distinguishedname}
    Write-Host "1: " + $elapsed.Elapsed.ToString()
    $Searcher.Filter = "(&(objectClass=user))"
    $Searcher.SizeLimit = 500
    $Results = $Searcher.FindAll()
    $userlist = $Results  | %{ if($_.Properties.iscriticalsystemobject -eq $null){$_.Properties.distinguishedname}}
    Write-Host "2: " + $elapsed.Elapsed.ToString()
            #get owner all parameters and store as variable to call upon later
            $ownerinfo = $userlist | Get-Random 
                    if ($PSBoundParameters.ContainsKey('Creator') -eq $true)
                        {$adminID = $Creator
                        }
                    else{$adminID = $wtfwasthis = ((whoami) -split '\\')[1]}
    
    Write-Host "3: " + $elapsed.Elapsed.ToString()
    #=======================================================================
    #name workflow
                #get aduser who is the administratorid/ownerid ($Owner) and use their 1st part of  for the prefix
            
            
            $computernameprefix1 = (Get-Random $3lettercodes).NAME
                                   
            $computernameprefix2 = 'W'
               
        #=======================================================================
        #WorkstationorServer 0 (workstation) prefix name workflow
        #=======================================================================
        $WorkstationOrServer = 0,1 |get-random #work =0, server = 1
        $WorkstationType = 0,1,2 |get-random # desktop = 0 , laptop = 1, vm = 2
        if($WorkstationOrServer -eq 0){
                if($WorkstationType -eq 0){ #desktop 
                    $computernameprefix2 = "WWKS"}
                                        
                                                    
                elseif($WorkstationType -eq 1){ #laptop workflow
                    $computernameprefix2 = "WLPT"}
                                                        
                else{
                    $computernameprefix2 = "WVIR"}
                            }
            
            
        #=======================================================================
        #WorkstationorServer 1 (server) prefix name workflow
        #=======================================================================
        else{
            $ServerApplication = 0,1,2,3,4,5|get-random
            if($ServerApplication -eq 0){$computernameprefix3 = "APPS"}
            elseif($ServerApplication -eq 1){$computernameprefix3 = "WEBS"}
            elseif($ServerApplication -eq 2){$computernameprefix3 = "DBAS"}
            elseif($ServerApplication -eq 3){$computernameprefix3 = "SECS"}
            elseif($ServerApplication -eq 4){$computernameprefix3 = "CTRX"}
            else{$computernameprefix3 = "APPS"}
        }    
                

Write-Host "4: " + $elapsed.Elapsed.ToString()
        $computernameprefixfull = $computernameprefix1 + $computernameprefix2 +$computernameprefix3
        $cnSearch = $computernameprefixfull +"*"
    #=======================================================================
    #End workstationorserver prefix name workflow
    #=======================================================================

    

    #Set OU Location - first test for parameter
        if ($PSBoundParameters.ContainsKey('OUlocation') -eq $true)
            {$ouLocation = $OUlocation
                #$computernameprefixfull = "RADWHWKS"
                
                if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                        {write-host OULocation for search $OUlocation -ForegroundColor Green
                        Write-host Computername Search string $cnSearch -ForegroundColor Green
                        }
                  
                    $Searcher.Filter = "(&(objectClass=computer)(name=*$cnsearch*))"
                    $Searcher.SearchRoot = "LDAP://" + $ouLocation
                    $Results = $Searcher.FindAll()
                
                    $comps =$Results | %{ $_.properties.name}
                    if($comps.count -eq 0){$compname = $computernameprefixfull + [convert]::ToInt32('1000000')}
                    else{
                        try{$compname = $computernameprefixfull + ([convert]::ToInt32((($comps[($comps.count -1)].name).Substring(($computernameprefixfull.Length),((($comps[($comps.count -1)].name).length)-($computernameprefixfull.Length)))),10) + 1)}
                        catch{$compname = $computernameprefixfull + [convert]::ToInt32('1000000')}
                        }
                
            }
        else{

        #workstation or server
            if ($WorkstationOrServer -eq 0){ #workstation build
            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {write-host Workstation Build Chosen
                                write-host `n}
            

                #end of name is 7 numbers characters 0-9
                #select all computers in the OU, sort by create date, filter out *9999*, filter out machines with letters at the end, get most recent add a digit to it
                Write-Host "5: " + $elapsed.Elapsed.ToString()
            
                #ou root created above
                        if($WorkstationType -eq 0){ #desktop workflow
                            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {write-host "Workstation Type 0 chosen. Desktop value selected"}
                                        $ouLocation = 'OU=Desktops,OU=Technology,' + $dnstring
                                            #test for OU existence, if not exist, put in  Admin OU
                                            try{$tst = [adsi]"LDAP://$OUlocation"; $tst | Out-Null}
                                            catch{$OUlocation = 'OU=Admin,' + $D.distinguishedname}
                                            Write-Host "6: " + $elapsed.Elapsed.ToString()
                                                    }
                        elseif($WorkstationType -eq 1){ #laptop workflow
                            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {write-host "Workstation Type 1 chosen. Laptop value selected"}
                        
                                        $ouLocation = 'OU=Laptops,OU=Technology,' + $dnstring
                                        #test for OU existence, if not exist, put in  Admin OU
                                        try{tst = [adsi]"LDAP://$OUlocation"; $tst | Out-Null}
                                        catch{$OUlocation = 'OU=Admin,' + $D.distinguishedname}
                
                                                    Write-Host "7: " + $elapsed.Elapsed.ToString()
                                                        }

                        else{
                            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {write-host "Workstation Type 2 or higher chosen. VM or other value selected"}
                                    
                                        $ouLocation = 'OU=Desktops,OU=Technology,' + $dnstring
                                        try{tst = [adsi]"LDAP://$OUlocation"; $tst | Out-Null}
                                        #test for OU existence, if not exist, put in  Admin OU
                                            catch{$OUlocation = 'OU=Admin,' + $D.distinguishedname}
                                            Write-Host "8: " + $elapsed.Elapsed.ToString()
                            }
                            
                            

                            }
            #=========================================
            # END WORKSTATION OU identification
            #=========================================
            <#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#>
            #=========================================
            #SERVER OU identification BEGINS HERE
                else{
                if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                    {write-host Server Build Chosen
                                    write-host `n}
            #=======================================================================
    
    #=======================================================================

        
                    }
            #=========================================
            # END SERVER OU identification
            #=========================================
            <#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#> 
              # removing containers right now. will add later $ousall += get-adobject -Filter {objectclass -eq 'container'} -ResultSetSize 300|where-object -Property objectclass -eq 'container'|where-object -Property distinguishedname -notlike "*}*"|where-object -Property distinguishedname -notlike  "*DomainUpdates*"

                    $ouLocation = $OUsall | Get-Random 
                    if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {write-host DNString equals $dnstring -ForegroundColor Green
                                write-host OWNER equals $owner
                                
                                write-host OULocation for search $OUlocation -ForegroundColor Green}
            }     
                    #Write-host Getting list of servers in the server OU to create a unique name -ForegroundColor Green
                    $Searcher.Filter = "(&(objectClass=computer)(name=*$cnsearch*))"
                    $Searcher.SearchRoot = "LDAP://" + $ouLocation
                    $Results = $Searcher.FindAll()
                
                    $comps =$Results | %{ $_.properties.name}
                    #Write-host List complete -ForegroundColor white
                    
                    #write-host on line 325
                    $checkforDupe = 0
                    if($comps.count -eq 0){
                        
                        $i= 0
                        $i = [convert]::ToInt32($i)
                        if ($PSBoundParameters.ContainsKey('Debug') -eq $true){
                            write-host in the compname creation loop at line 329
                            }
                        do{
                            $compname = $computernameprefixfull + ([convert]::ToInt32('1000000')+($i))
                            
                            $i =$i + (random -Minimum 1 -Maximum 10)
                                try{
                                #write-host doing TRY get-adcomputer $compname
                                 $Searcher.Filter = "(&(objectClass=computer)(name=$compname))"
                                 $Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName
                                 $Results = $Searcher.FindAll()
                                 $checkforDupe = $Results.Count - 1
                                 Write-Host "L1: $compname " + $elapsed.Elapsed.ToString()
                               } catch{
                                #write-host doing Catch
                                $checkforDupe = 1}}
                    
                        while($checkforDupe -eq 0)
                            
                        }
                    else{
                        $i = 1
                        $i = [convert]::ToInt32($i)
                        do{
                        
                        if ($PSBoundParameters.ContainsKey('Debug') -eq $true){
                            write-host in the compname creation loop at line 393
                            }
                        else{}
                        
                            #write-host first try catch at 411
                        try{$compname = $computernameprefixfull + ([convert]::ToInt32((($comps[($comps.count -1)].name).Substring(($computernameprefixfull.Length),((($comps[($comps.count -1)].name).length)-($computernameprefixfull.Length)))),10) + $i)}
                        catch{$compname = $computernameprefixfull + ([convert]::ToInt32('1000000') + ($i))}
                        
                       
                                try{
                                 $Searcher.Filter = "(&(objectClass=computer)(name=$compname))"
                                 $Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName
                                 $Results = $Searcher.FindAll()
                                  $checkforDupe = $Results.Count - 1
                                     }
                                catch{$checkforDupe = 1}
                                $i++
                        
                            
                        }
                        
                        
                        while($checkforDupe -eq 0)
                            
                        }
                
            
        
        
        #Windows apple or Unix
        #infrastructure or application
            

    $ou = $oulocation
        [System.Collections.ArrayList]$att_to_add = @('servicePrincipalName')
    

    $division = $computernameprefix1

    $manager = $ownerinfo
    $sam = ($CompName) + "$"

    $DNS = 1..100|get-random
    if ($DNS -le 10)
            {
            $servicePrincipalName = "HOST/"+$compname
            }
        else{
            $att_to_add.Remove('servicePrincipalName')
            }

    #make the machine in this decision
    
            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {
                                write-host `n
                                write-host "New-ADComputer -server $setdc -Name $CompName -DisplayName $CompName -Enabled $true -path $ou -ManagedBy $manager -owner $owner -SAMAccountName $sam"
                                write-host `n}
                                $description = 'Created with secframe.com/badblood.'
                                $new = $null
                                try{
                                    [adsi]$OU = "LDAP://$ou"
                                    $new = $OU.Create("Computer","CN=$CompName")
                                    $new.CommitChanges()
                                }catch{
                                    [adsi]$OU = "LDAP://" + $Domain.distinguishedName
                                    $new = $OU.Create("Computer","CN=$CompName")
                                    $new.CommitChanges()
                                    $new.put('managedby',$manager)
                               
                                }
                                if($new -eq $null)
                                {
                                    return
                                }
                                #  Enabled $true -path $ou -ManagedBy $manager -SAMAccountName $sam -Description $Description}
                                   $new.put('samaccountname',$sam)
                                    $new.put('description',$Description)
                                    $new.CommitChanges()


            #something is up with system containers i  pull in earlier.  try the random path.  if doesnt work set to default computer container
                              #  try{New-ADComputer -server $setdc -Name $CompName -DisplayName $CompName -Enabled $true -path $ou -ManagedBy $manager -SAMAccountName $sam -Description $Description}
                               # catch{New-ADComputer -server $setdc -Name $CompName -DisplayName $CompName -Enabled $true -ManagedBy $manager -SAMAccountName $sam -Description $Description}


    #Check for machine.  if it does not exist, skip this next parameter setting stuff
    $results = $null
    try{
    $Searcher.Filter = "(&(objectClass=computer)(name=$compname))"
    $Searcher.SearchRoot = "LDAP://" + $Domain.distinguishedName
    $Results = $Searcher.FindAll()
    $z = [adsi]"LDAP://$(*$Results | select -first 1).distinguishedname)"
            foreach ($a in $att_to_add){
                            $var = iex $("$"+$a)
                            #comment out bottom line once debugging complete
                            if ($PSBoundParameters.ContainsKey('Debug') -eq $true)
                                {
                                   # write-host on $a parameter with variable $var
                                }
                            $z.put($a,$($var))
                            #get-adcomputer $sam -server $setdc  |Set-ADComputer -server $setdc -replace @{$a = $($var)}
                        }
                    #write-host `n
                    
                    #$results = Get-ADComputer $sam  -server $setdc -Properties * 
                    #$results |select CN,department,departmentNumber,Description,DisplayName,DistinguishedName,division,DNSHostName,ManagedBy,Name,SamAccountName,serialNumber,servicePrincipalName,ServicePrincipalNames


                    
                    #write-host `n
                    #write-host Machine $results.samaccountname created in ((get-addomain).distinguishedname) in OU $OUlocation
                    
                       $z.CommitChanges()
                   
                    }
    catch {
    #write-host Machine $sam was not created with code:
    #write-host "New-ADComputer -Name $CompName -DisplayName $CompName -Enabled $true -path $ou -ManagedBy $manager -SAMAccountName $sam"
    }
  

    $done = @()


}
Function NewComputers{
    param(
    
        $NumberOfMachines
    )

if ($PSBoundParameters.ContainsKey('NumberOfMachines') -eq $false){
            $NumberofMachines = 5
            #write-host No number specified.  Defaulting to create 5 machines
                        }
                        

$i = 1
do {
    CreateComputer
$i++

}
while ($i -le $NumberOfMachines)


}
