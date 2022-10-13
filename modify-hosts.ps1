# ==============================
# 
# Add, remove or show entries in hosts file
#
# ==============================

WriteHeader "Add, remove or show entries in hosts file"

#Modify Windows hosts-file

$file = "C:\Windows\System32\drivers\etc\hosts"

Function Add-Host([string] $filename, [string] $ip, [string] $hostname) {
	# remove-host $filename $hostname
	$ip + "`t`t" + $hostname | Out-File -encoding ASCII -append $filename
	WriteDebug "Added $ip $hostname to $filename"
	WriteLine
	Write-Host
}

Function Remove-Host([string]$filename, [string]$hostname){
	$c = Get-Content $filename
	$newLines = @()
	
	foreach ($line in $c) {
		$bits = [regex]::Split($line, "\t+")
		if ($bits.count -eq 2) {
			if ($bits[1] -ne $hostname) {
				$newLines += $line
			}
		} else {
			$newLines += $line
		}
	}
	
	# Write file
	Clear-Content $filename
	foreach ($line in $newLines) {
		$line | Out-File -encoding ASCII -append $filename
	}
}

try {
	if ($args[0] -eq "add") {
	
		if ($args.count -lt 3) {
			throw "Not enough arguments for add."
		} else {
			add-host $file $args[1] $args[2]
		}
		
	} elseif ($args[0] -eq "remove") {
	
		if ($args.count -lt 2) {
			throw "Not enough arguments for remove."
		} else {
			remove-host $file $args[1]
		}
		
	} elseif ($args[0] -eq "show") {
		print-hosts $file
	} else {
		throw "Invalid operation '" + $args[0] + "' - must be one of 'add', 'remove', 'show'."
	}
} catch  {
	Write-Host $error[0]
	Write-Host "`nUsage: hosts add <ip> <hostname>`n       hosts remove <hostname>`n       hosts show"
}