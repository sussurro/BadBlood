<#
    .Synopsis
       Generates users, groups, OUs, computers in an active directory domain.  Then places ACLs on random OUs
    .DESCRIPTION
       This tool is for research purposes and training only.  Intended only for personal use.  This adds a large number of objects into a domain, and should never be  run in production.
    .EXAMPLE
       There are currently no parameters for the tool.  Simply run the ps1 as a DA and it begins. Follow the prompts and type 'badblood' when appropriate and the tool runs.
    .OUTPUTS
       [String]
    .NOTES
       Written by David Rowe, Blog secframe.com
       Twitter : @davidprowe
       I take no responsibility for any issues caused by this script.  I am not responsible if this gets run in a production domain. 
      Thanks HuskyHacks for user/group/computer count modifications.  I moved them to parameters so that this tool can be called in a more rapid fashion.
    .FUNCTIONALITY
       Adds a ton of stuff into a domain.  Adds Users, Groups, OUs, Computers, and a vast amount of ACLs in a domain.
    .LINK
       http://www.secframe.com/badblood
   
    #>
[CmdletBinding()]
    
param
(
   [Parameter(Mandatory = $false,
      Position = 1,
      HelpMessage = 'Supply a count for user creation default 2500')]
   [Int32]$UserCount = 2500,
   [Parameter(Mandatory = $false,
      Position = 2,
      HelpMessage = 'Supply a count for user creation default 500')]
   [int32]$GroupCount = 500,
   [Parameter(Mandatory = $false,
      Position = 3,
      HelpMessage = 'Supply the script directory for where this script is stored')]
   [int32]$ComputerCount = 100,
   [Parameter(Mandatory = $false,
      Position = 4,
      HelpMessage = 'Skip the OU creation if you already have done it')]
   [switch]$SkipOuCreation,
   [Parameter(Mandatory = $false,
      Position = 5,
      HelpMessage = 'Skip the LAPS deployment if you already have done it')]
   [switch]$SkipLapsInstall,
   [Parameter(Mandatory = $false,
      Position = 6,
      HelpMessage = 'Make non-interactive for automation')]
   [switch]$NonInteractive
)
function Get-ScriptDirectory {
   Split-Path -Parent $PSCommandPath
}
$basescriptPath = Get-ScriptDirectory
$totalscripts = 7

$i = 0
cls
write-host "Welcome to BadBlood"
if($NonInteractive -eq $false){
    Write-Host  'Press any key to continue...';
    write-host "`n"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
write-host "The first tool that absolutely mucks up your TEST domain"
write-host "This tool is never meant for production and can totally screw up your domain"

if($NonInteractive -eq $false){
    Write-Host  'Press any key to continue...';
    write-host "`n"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
Write-Host  'Press any key to continue...';
write-host "You are responsible for how you use this tool. It is intended for personal use only"
write-host "This is not intended for commercial use"
if($NonInteractive -eq $false){
    Write-Host  'Press any key to continue...';
    write-host "`n"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
write-host "`n"
write-host "Domain size generated via parameters `n Users: $UserCount `n Groups: $GroupCount `n Computers: $ComputerCount"
write-host "`n"
$badblood = "badblood"
if($NonInteractive -eq $false){

    $badblood = Read-Host -Prompt "Type `'badblood`' to deploy some randomness into a domain"
    $badblood.tolower()
    if ($badblood -ne 'badblood') { exit }
}
if ($badblood -eq 'badblood') {

   $Domain = Get-addomain

   # LAPS STUFF
   if ($PSBoundParameters.ContainsKey('SkipLapsInstall') -eq $false)
      {
         Write-Progress -Activity "Random Stuff into A domain" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
         .($basescriptPath + '\AD_LAPS_Install\InstallLAPSSchema.ps1')
	 if($NonInteractive -eq $false){
             Write-Progress -Activity "Random Stuff into A domain: Install LAPS" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
         }
      }
   else{}
   
   $I++

   $initUsers = Get-ADUser -Filter * | %{ $_.DistinguishedName}
   $initOU = Get-ADOrganizationalUnit -Filter * | %{ $_.DistinguishedName }
   $initGroups = Get-ADGroup -Filter * | %{$_.DistinguishedName}

   #OU Structure Creation
   if ($PSBoundParameters.ContainsKey('SkipOuCreation') -eq $false)
      {
         .($basescriptPath + '\AD_OU_CreateStructure\CreateOUStructure.ps1')
         if($NonInteractive -eq $false){
              Write-Progress -Activity "Random Stuff into A domain - Creating OUs" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
         }
      }
   else{}
   $I++


   # User Creation
   $ousAll = Get-adorganizationalunit -filter * | %{ if(-not $initOU.contains($_.Distinguishedname)){$_}}
   write-host "Creating Users on Domain" -ForegroundColor Green
    
   $x = 1
   if($NonInteractive -eq $false){
       Write-Progress -Activity "Random Stuff into A domain - Creating Users" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   $I++
   .($basescriptPath + '\AD_Users_Create\CreateUsers.ps1')
   $createuserscriptpath = $basescriptPath + '\AD_Users_Create\'

   $RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
   $RunspacePool.Open()
   $Jobs = @()

   $userblock = {
    Param(
        $basescriptPath,
        $Domain,
        $ousAll)
     . ($basescriptPath + '\AD_Users_Create\CreateUsers.ps1')
     $createuserscriptpath = $basescriptPath + '\AD_Users_Create\'

     CreateUser -Domain $Domain -OUList $ousAll -ScriptDir $createuserscriptpath
   }



   do {

      $PowerShell = [powershell]::Create()
      $PowerShell.RunspacePool = $RunspacePool

      $null = $PowerShell.AddScript($userblock).AddArgument($basescriptpath).AddArgument($Domain).AddArgument($ousAll)

      $Jobs += $PowerShell.BeginInvoke()
       $x++

   }while ($x -lt $UserCount)

   while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
   }

   $Jobs = @()
   #Group Creation
   $I++
   $AllUsers = Get-aduser -Filter * | %{ if(-not $initUsers.contains($_.Distinguishedname)){$_}}
   if($NonInteractive -eq $false){
      Write-Progress -Activity "Random Stuff into A domain - Creating Groups" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   write-host "Creating Groups on Domain" -ForegroundColor Green

   $x = 1
   .($basescriptPath + '\AD_Groups_Create\CreateGroups.ps1')
    
   do {
      $PowerShell = [powershell]::Create()
      $PowerShell.RunspacePool = $RunspacePool
      $PowerShell.AddScript({CreateGroup}) | Out-Null
      $Jobs += $PowerShell.BeginInvoke() | Out-Null

      $x++
   }while ($x -lt $GroupCount)
   while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
   }


   $Grouplist = Get-ADGroup -Filter { GroupCategory -eq "Security" -and GroupScope -eq "Global" } -Properties isCriticalSystemObject | %{ if(-not $initGroups.contains($_.Distinguishedname)){$_}}
   $LocalGroupList = Get-ADGroup -Filter { GroupScope -eq "domainlocal" } -Properties isCriticalSystemObject

   #Computer Creation Time
   write-host "Creating Computers on Domain" -ForegroundColor Green
   $I++
   $X = 1
   $Jobs = @()
   if($NonInteractive -eq $false){
       Write-Progress -Activity "Random Stuff into A domain - Creating Computers" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   .($basescriptPath + '\AD_Computers_Create\CreateComputers.ps1')

   do {
      $PowerShell = [powershell]::Create()
      $PowerShell.RunspacePool = $RunspacePool
      $PowerShell.AddScript({createcomputer}) | Out-Null
      $Jobs += $PowerShell.BeginInvoke()
      $x++
   }while ($x -lt $ComputerCount)
   while ($Jobs.IsCompleted -contains $false) {
        Start-Sleep -Milliseconds 100
   }

   $Complist = get-adcomputer -filter *
    

   #Permission Creation of ACLs
   $I++
   write-host "Creating Permissions on Domain" -ForegroundColor Green
   if($NonInteractive -eq $false){
      Write-Progress -Activity "Random Stuff into A domain - Creating Random Permissions" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   .($basescriptPath + '\AD_Permissions_Randomizer\GenerateRandomPermissions.ps1')
    
    
   # Nesting of objects
   $I++
   write-host "Nesting objects into groups on Domain" -ForegroundColor Green
   .($basescriptPath + '\AD_Groups_Create\AddRandomToGroups.ps1')
   if($NonInteractive -eq $false){
      Write-Progress -Activity "Random Stuff into A domain - Adding Stuff to Stuff and Things" -Status "Progress:" -PercentComplete ($i / $totalscripts * 100)
   }
   AddRandomToGroups -Domain $Domain -Userlist $AllUsers -GroupList $Grouplist -LocalGroupList $LocalGroupList -complist $Complist

   write-host "Creating random SPNs" -ForegroundColor Green
   .($basescriptpath + '\AD_SPN_Randomizer\GenerateRandomSPNs.ps1')
   CreateRandomSPNs -SPNCount 50
    


}
