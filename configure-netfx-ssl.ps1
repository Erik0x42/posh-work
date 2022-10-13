<#
.SYNOPSIS
	Disable known weak cryptographic protocols
.NOTES    
	Instructs Schannel to disable known weak cryptographic algorithms, cipher suites, and SSL/TLS protocol versions that may be otherwise enabled for better interoperability.
    In .Net framework 4.5.2 and below, if strong cryptography is not set, SSL 3.0 or TLS 1.0 will be used by default.
    For .Net 4.6.1 strong cryptography is enabled by default, meaning that secure HTTP communications will use TLS 1.0, TLS 1.1 or TLS 1.2.
#>  

   	$regKey1 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
	$regParam1 = "SchUseStrongCrypto"
	$regValue1 = "1"
	$regKey2 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319"
	$regParam2 = "SchUseStrongCrypto"
	$regValue2 = "1"

	Set-RegistryKey -Key $regKey1 -Name $regParam1 -Value $regValue1
	Set-RegistryKey -Key $regKey2 -Name $regParam2 -Value $regValue2
