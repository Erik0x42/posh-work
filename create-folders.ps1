# ==============================
# 
# Create folders
#
# ==============================

WriteHeader "Create folders and Assign user rights"

# Region Create folders and set permissions
if (Confirm "Create folders and set permissions") {
	$iisFolders | ForEach-Object {
		New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue
	}

	#Set rights
	$rights = "Modify"
	$type = "Allow"
	$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", $rights, 3, 0, $type)
	WriteDebug "Add Modify for IIS_IUSRS on folders:"
	$iisFolders | ForEach-Object {
		WriteDebug "- $_"
		$ACL = Get-Acl $_
		$ACL.AddAccessRule($accessRule)
		Set-Acl $_ -AclObject $ACL
	}
	Set-Acl $webSitesRoot -AclObject $ACL
	Set-Acl $webSitesLogs -AclObject $ACL

	WriteDone
}
# EndRegion
