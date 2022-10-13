# ==============================
# 
# Global Functions
#
# ==============================

Function WriteLine
{
    Write-Host -ForegroundColor Green "# ------------------------------------------------------------"
}

Function WriteDoubleLine
{
    Write-Host -ForegroundColor Green "# ============================================================"
}

Function WriteWarning ($text)
{
    Write-Host -ForegroundColor Yellow "+"
    Write-Host -ForegroundColor Yellow "+ $text"
    Write-Host -ForegroundColor Yellow "+"
}

Function WriteError ($text)
{
    Write-Host -ForegroundColor Red "!"
    Write-Host -ForegroundColor Red "! $text"
    Write-Host -ForegroundColor Red "!"
}

Function Ask ($text)
{
	Write-Host -ForegroundColor White ">"
	Write-Host -ForegroundColor White -NoNewline "> $text "

	$reply = Read-Host
	return $reply
}

Function Confirm ($text)
{
	Write-Host -ForegroundColor White ">"
	Write-Host -ForegroundColor White -NoNewline "> $text [y/n]: "
	$reply = Read-Host
	if ( $reply -match "[yY]" ) { 
		return $true
	}
	else {
		return $false
	}
}

Function WriteDebug ($text)
{
	if ($isDebug)
	{
		Write-Host -ForegroundColor Green "# $text"
	}
}

Function WriteVerbose ($text)
{
	Write-Host -ForegroundColor White "> $text"
}

Function WritePause ($text)
{
	if ($isDebug)
	{
		WriteDebug $text
		Pause
	}
}

Function WriteDone ()
{
    if ($isDebug)
	{
        WriteDebug "Done..."
        #Pause
    }
}

Function WriteHeader ($text)
{
    Write-Host
	WriteDoubleLine
	WriteDebug
	WriteDebug $text
	WriteDebug
	WriteDoubleLine
    Write-Host
}

Function Get-Site
{
	$fqdn = Get-FQDN
	$site = "NOTSET"
	if ($fqdn -like 'fp-*') {
		$site = "PPU"
	}
	if ($fqdn -like 'f-*') {
		$site = "Prod"
	}
	return $site
}

Function Get-FQDN
{
	$path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
	$hostname = (Get-ItemProperty -Path $path -Name "Hostname")."Hostname"
	$domainname = (Get-ItemProperty -Path $path -Name "Domain")."Domain"
	$fqdn = $hostname + "." + $domainname
	return $fqdn
}

Function Get-HostName
{
	$path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
	$hostname = (Get-ItemProperty -Path $path -Name "Hostname")."Hostname"
	return $hostname
}

# Function Used for variables in Azure DevOps containing other variables
Function Expand-Variable ($text) {
	$text = $text -replace '[()]',''
	$value = $ExecutionContext.InvokeCommand.ExpandString($text)
	return $value
}

Function Add-UserToLocalGroup 
{
	<# 
	.SYNOPSIS 
		Add a user to a local group
	.DESCRIPTION
		This function adds a user to a local group with check and error handling
	.SYNTAX
		AddUserToLocalGroup UserName<String> Group<String>
	.Notes 
		Author : Bjarne L. Gram 
	#> 
	param (
		[String]
		$Member,
		[String]
		$Group
	)

	WritePause "Assign user $Member to local group $Group"
	$userExistInGroup = Get-LocalGroupMember -Group $Group -Member $Member -ErrorAction SilentlyContinue
	if ($userExistInGroup) {
		WriteDebug "$Member is a member of local group $Group"
	}
	else {
		Add-LocalGroupMember -Group $Group -Member $Member
		WriteDebug "User $Member added to local group $Group"
	}
}

Function CreateLocalAccount ($user)
{
	<# 
		.SYNOPSIS 
			Create a new Local User
		.DESCRIPTION
			This function creates a new local user account if it doesn't exist
		.SYNTAX
			CreateLocalAccount UserName<String>
		.Notes 
			Author : Bjarne L. Gram 
    #> 
	$userExist = Get-LocalUser -Name $user -ErrorAction SilentlyContinue
	if($userExist)
	{
		WriteWarning "The user account $user allready exists."
	}
	else
	{
		WriteWarning "Input password for Service Account: "
		$Password = Read-Host -AsSecureString
		New-LocalUser $user -Password $Password
	}

}

Function Set-RegistryKey
{
	<# 
	.SYNOPSIS 
		Set a registry key value
	.DESCRIPTION
		This function sets a registry key value and creates the key and/or property if neccessary
	.SYNTAX
		Set-RegistryKey Key<String> Name<String> Value<String>
	.Notes 
		Author : Bjarne L. Gram 
	#> 
	param (
		[Parameter(Mandatory=$true)]
		[String] $Key,
		[Parameter(Mandatory=$true)]
		[String] $Name,
		[Parameter(Mandatory=$true)]
		[String] $Value
	)

	WriteHeader "This function sets a registry key value and creates the key and/or property if neccessary"

	if (Test-Path $Key)
	{
		WriteDebug "Registry key $Key exists"
		Write-Host
	}
	else
	{
		WriteError "Registry key $Key doesn't exist!"
		WriteError "Hit Ctrl-C to break"
		Pause
	}

	$regParamExists = Get-ItemProperty $Key -Name $Name -ErrorAction SilentlyContinue
	if ($regParamExists) {
		$regParamValue = Get-ItemPropertyValue $Key -Name $Name -ErrorAction SilentlyContinue
		WriteDebug "Registry parameter $Name exists and the value is $regParamValue"
		Write-Host
	}
	else {
		WriteDebug "Registry parameter $Name doesn't exist, creating it"
		New-ItemProperty $Key -Name $Name -PropertyType DWORD
	}

	if ($regParamValue -ne $Value)
	{
		WriteVerbose "Setting registry key $Key paramter $Name to value $Value"
		Write-Host
		Set-ItemProperty $Key -Name $Name -Value $Value

		WriteWarning "This will require a restart to be set"
	}
	else
	{
		WriteVerbose "The registry current value and new value are identical."
		WriteVerbose "Skipping any changes"
	}

	Write-Host
	WriteDone
}

Function Get-InternetProxy
{ 
    <# 
            .SYNOPSIS 
                Determine the internet proxy address
            .DESCRIPTION
                This function allows you to determine the the internet proxy address used by your computer
            .EXAMPLE 
                Get-InternetProxy
            .Notes 
                Author : Antoine DELRUE 
                WebSite: http://obilan.be 
    #> 

    $proxies = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').proxyServer

    if ($proxies)
    {
        if ($proxies -ilike "*=*")
        {
            $proxies -replace "=","://" -split(';') | Select-Object -First 1
        }

        else
        {
            "http://" + $proxies
        }
    }    
	else {
		"No proxies detected"
	}
}

function Test-Cred {
           
    [CmdletBinding()]
    [OutputType([String])] 
       
    Param ( 
        [Parameter( 
            Mandatory = $false, 
            ValueFromPipeLine = $true, 
            ValueFromPipelineByPropertyName = $true
        )] 
        [Alias( 
            'PSCredential'
        )] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] 
        $Credentials
    )
    $Domain = $null
    $Root = $null
    $Username = $null
    $Password = $null
      
    If($Credentials -eq $null)
    {
        Try
        {
            $Credentials = Get-Credential "domain\$env:username" -ErrorAction Stop
        }
        Catch
        {
            $ErrorMsg = $_.Exception.Message
            Write-Warning "Failed to validate credentials: $ErrorMsg "
            Pause
            Break
        }
    }
      
    # Checking module
    Try
    {
        # Split username and password
        $Username = $credentials.username
        $Password = $credentials.GetNetworkCredential().password
  
        # Get Domain
        $Root = "LDAP://" + ([ADSI]'').distinguishedName
        $Domain = New-Object System.DirectoryServices.DirectoryEntry($Root,$UserName,$Password)
    }
    Catch
    {
        $_.Exception.Message
        Continue
    }
  
    If(!$domain)
    {
        Write-Warning "Something went wrong"
    }
    Else
    {
        If ($domain.name -ne $null)
        {
            return "Authenticated"
        }
        Else
        {
            return "Not authenticated"
        }
    }
}

Function Copy-WithProgress
{
<# 
    .SYNOPSIS 
        Copy files with progress-bar
    .DESCRIPTION
        This function copies all files from $Source to $Destination while displaying a progress-bar
    .EXAMPLE 
        Copy-WithProgress C:\temp d:\temp $true
    .Notes 
        Author : Dr Scripto with modifications by Budmod project
        WebSite: https://devblogs.microsoft.com/scripting/build-a-better-copy-item-cmdlet-2/ 
#> 
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        $Source,
        [Parameter(Mandatory=$true)]
        $Destination,
	[Parameter(Mandatory=$true)]
	$Force
    )

    $Source=$Source.tolower()
    $Filelist=Get-Childitem "$Source" -Recurse
    $Total=$Filelist.count
    $Position=0

    foreach ($File in $Filelist)
    {
        $Filename=$File.Fullname.tolower().replace($Source,'')
        $DestinationFile= Join-Path $Destination $Filename
        Write-Progress -Activity "Copying data from '$source' to '$Destination'" -Status "Copying File $Filename" -PercentComplete (($Position/$total)*100)
		if ($Force) {Copy-Item $File.FullName -Destination $DestinationFile -Force}
		else {Copy-Item $File.FullName -Destination $DestinationFile}
        
        $Position++
    }
}

Function Get-NetshSetup($sslBinding='0.0.0.0:443') {
<# 
    .SYNOPSIS 
        Get SSL Setup
    .DESCRIPTION
        This function uses netsh hhtp show to get all SSL setup
    .EXAMPLE 
        Get-NetshSetup 0.0.0.0:443
    .Notes 
        WebSite: https://toreaurstad.blogspot.com/2018/10/working-with-netsh-http-sslcert-setup.html 
#> 

$sslsetup = netsh http show ssl $sslBinding

$sslsetupKeys = @{}

foreach ($line in $sslsetup){
 if ($line -ne $null -and $line.Contains(': ')){
    
    $key = $line.Split(':')[0]
    $value = $line.Split(':')[1]
     if (!$sslsetupKeys.ContainsKey($key)){
       $sslsetupKeys.Add($key.Trim(), $value.Trim()) 
      }
    } 
}

return $sslsetup
}

