# ==============================
# 
# Import Certificate budmod.dep.no
#
# ==============================

WriteHeader "Import Certificate"

$certPath = Join-Path $scriptsFolder $pfxFileName
$certStore = "Cert:\LocalMachine\My"
$secPfxPwd = Read-Host -AsSecureString "Password for $pfxFileName"

WriteDebug "Certificate path: $certPath"

Import-PfxCertificate -CertStoreLocation $certStore -FilePath $certPath -Password $secPfxPwd

# Set access right for service account
$certPermission = "read"

try {
	# Get Certificate
	$cert = Get-ChildItem -Path $certStore | Where-Object {$_.Thumbprint -eq $sslThumbprint}
	$keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"; 
	$keyName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
	$keyFullPath = $keyPath + $keyName;
	WriteDebug "Found Certificate..."
	WriteDebug "Granting access to $appPoolAccount..."
    $acl = (Get-Item $keyFullPath).GetAccessControl('Access') #Get Current Access
    $buildAcl = New-Object  System.Security.AccessControl.FileSystemAccessRule($appPoolAccount,$certPermission,0) #Build Access Rule
    $acl.SetAccessRule($buildAcl) #Add Access Rule
    Set-Acl $keyFullPath $acl #Save Access Rules
}
catch {
	WriteError "Unable to grant access..."
	WriteError "An error occurred:"
	WriteError $_
}
