# ================================
#
# Script to restore items from Recycle Bin
#
# ================================

#Requires -RunAsAdministrator

# Import the interactive menu module
using module InteractiveMenu

$dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
$logFile = "restore-log-$env:COMPUTERNAME-$dateStamp.log"
$logFile = Join-Path $PSScriptRoot $logFile

Write-Host -ForegroundColor Green "# Starting Transcript to file $logFile"
# Start-Transcript -Path $logFile

# Include Functions
. "$PSScriptRoot\include-functions.ps1"

#Debug true
$isDebug = $true

$menuItems = @(
    [InteractiveMultiMenuItem]::new("user", "Deleted by user", $false, 0, $false, "Restore files deleted by specified user.")
    [InteractiveMultiMenuItem]::new("onedate", "Deleted on date", $false, 1, $false, "Restore files deleted on a specific date.")
    [InteractiveMultiMenuItem]::new("datespan", "Deleted date span", $false, 1, $false, "Restore files deleted between two dates.")
    [InteractiveMultiMenuItem]::new("filetype", "File type", $false, 1, $false, "Restore files of a specified filetype (one file type only).")
)

WriteHeader "Script to restore files from SharePoint online recycle bin"

$siteUrl = Ask "Which Site Collection do you want to restore files from:"
$siteUrl = $siteUrl.TrimEnd('/')
$conf = Confirm "Is the URL to the Site Collection: $siteUrl correct?"

WriteVerbose

$count = (Get-PnPRecycleBinItem).count
WriteVerbose "The number of files in the Recycle bin is: $count"

# Define the header of the menu
$header = "Filter which files to restore"

# Instantiate new menu object
$menu = [InteractiveMultiMenu]::new($header, $menuItems);

# [Optional] You can change the colors and the symbols
$options = @{
    HeaderColor = [ConsoleColor]::Green;
    HelpColor = [ConsoleColor]::Cyan;
    CurrentItemColor = [ConsoleColor]::DarkGreen;
    LinkColor = [ConsoleColor]::DarkCyan;
    CurrentItemLinkColor = [ConsoleColor]::Black;
    MenuDeselected = "[ ]";
    MenuSelected = "[x]";
    MenuCannotSelect = "[/]";
    MenuCannotDeselect = "[!]";
    MenuInfoColor = [ConsoleColor]::DarkYellow;
    MenuErrorColor = [ConsoleColor]::DarkRed;
}
$menu.SetOptions($options)

# Trigger the menu and receive the user selections
$selectedItems = $menu.GetSelections()

# Set up the filter string
$pnpFilter = ""
$userName = ""

foreach ($item in $selectedItems)
{
    if($item -eq "user")
    {
        $userName = Ask "Input the users email adress (of the user that deleted the files):"
    }

    if($item -eq "onedate")
    {
        $deletedDate = Ask "Input the date files were deleted [[yyyy-mm-dd]:"
    }

    if($item -eq "datespan")
    {
        $fromDate = Ask "Input the date the files were deleted after (from date [yyyy-mm-dd]):"
        $toDate = Ask "Input the date the files were deleted before (to date [yyyy-mm-dd]):"
    }

    if($item -eq "filetype")
    {
        $fileType = Ask "Which type of files are to be restored (*.ext - one file type only):"
    }
}
# Get-PnPRecycleBinItem | ? {($_.DeletedDate -gt $date2 -and $_.DeletedDate -lt $date1) -and ($_.DeletedByEmail -eq 'john@contoso.com')}  | select -last 10 | fl *