# If script isn't running as admin, restart with admin privileges
If (([Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -ne "S-1-5-32-544") {
    $terminal = "powershell"
    if (Get-Command wt -ErrorAction SilentlyContinue) { $terminal = "wt" }
    Start-Process wt -Verb RunAs "PowerShell -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Set application theme based on AppsUseLightTheme prefrence
$theme = @("#ffffff","#202020","#323232")
if (Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme") {
    $theme = @("#292929","#f3f3f3","#fbfbfb")
}

# Install and unzip ADB to selected path & add to PATH environment variable
function install_adb($selected_path) {
    Write-Host "Installing ADB (Android Debug Bridge): https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    Start-BitsTransfer "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -Destination "$selected_path"
    Expand-Archive "$selected_path\platform-tools-latest-windows.zip" -Destination "$selected_path"
    if (Test-Path "$selected_path\platform-tools") {
        Remove-Item "$selected_path\platform-tools-latest-windows.zip"
        Write-Host "Making ADB Available User-wide"
        Set-Item -Path Env:\PATH -Value ("$env:PATH;$selected_path\platform-tools")
        [Environment]::SetEnvironmentVariable("Path","$env:PATH","User")
        Write-Host "Successfully Installed ADB to: '$selected_path\platform-tools'`nNote: You may need to restart the PowerShell window to access ADB"
        $install.Text = "Update"
        $uninstall.Show()
    }
}

# Install Universal ADB Driver
function install_adbdrivers {
    Write-Host "`nInstalling Universal ADB Driver: https://adb.clockworkmod.com/"
    Start-BitsTransfer "https://github.com/koush/adb.clockworkmod.com/releases/latest/download/UniversalAdbDriverSetup.msi"
    .\UniversalAdbDriverSetup.msi /passive
    while (!(Get-Package -Name "Universal Adb Driver" -ErrorAction SilentlyContinue)) {}
    Write-Host "Successfully Installed Universal ADB Driver"
    Remove-Item .\UniversalAdbDriverSetup.msi
}

# Get ADB location and delete directory, then remove from PATH
function uninstall_adb {
    $location = "$env:PATH".split(";") | Select-String "platform-tools"
    Write-Host "Removing ADB from: $location"
    Remove-Item -Recurse "$location"
    [Environment]::SetEnvironmentVariable("Path",$env:PATH.replace(";$location",""),"User")
    $install.Text = "Install"
    $uninstall.Hide()
}

# Uninstall Universal ADB Driver and delete its directory
function uninstall_adbdrivers {
    Write-Host "Attempting to Uninstall Universal ADB Driver"
    Get-Package -Name "Universal Adb Driver" -ErrorAction SilentlyContinue | Uninstall-Package
    Get-Item "C:\Program Files (x86)\ClockworkMod\Universal Adb Driver" | % { Remove-Item -Recurse "$_" }
}

# GUI specs
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$window = New-Object System.Windows.Forms.Form
$window.Text = "ADB Wizard"
$window.StartPosition = "CenterScreen"
$window.ClientSize = New-Object System.Drawing.Point(550,300)
$window.ForeColor = $theme[0]
$window.BackColor = $theme[1]

# Instructional text
$description = New-Object System.Windows.Forms.Label
$description.Text = "Welcome to ADB Wizard, a graphical tool designed to effortlessly install ADB (Android Debug Bridge) user-wide on Windows. Please Select an installation directory for ADB."
$description.Size = New-Object System.Drawing.Size(400,40)
$description.Location = New-Object System.Drawing.Size(10,20)
$description.ForeColor = $theme[0]

# Buttons
$filepath = New-Object System.Windows.Forms.Textbox
$filepath.Text = ("$HOME")
$filepath.Size = New-Object System.Drawing.Size(400,40)
$filepath.Location = New-Object System.Drawing.Size(140,130)
$filepath.ForeColor = $theme[0]
$filepath.BackColor = $theme[2]

$adbdrivers = New-Object System.Windows.Forms.CheckBox
$adbdrivers.Text = "Install Universal ADB Drivers (Optional)"
$adbdrivers.Size = New-Object System.Drawing.Size(220,20)
$adbdrivers.Location = New-Object System.Drawing.Size(140,155)
$adbdrivers.FlatStyle = "0"
$adbdrivers.FlatAppearance.BorderSize = "0"
$adbdrivers.ForeColor = $theme[0]

$browse = New-Object System.Windows.Forms.Button
$browse.Text = "Browse"
$browse.Size = New-Object System.Drawing.Size(120,40)
$browse.Location = New-Object System.Drawing.Size(10,120)
$browse.FlatStyle = "0"
$browse.FlatAppearance.BorderSize = "0"
$browse.BackColor = $theme[2]

$install = New-Object System.Windows.Forms.Button
$install.Text = "Install"
$install.Size = New-Object System.Drawing.Size(120,40)
$install.Location = New-Object System.Drawing.Size(410,250)
$install.FlatStyle = "0"
$install.FlatAppearance.BorderSize = "0"
$install.BackColor = $theme[2]

$uninstall = New-Object System.Windows.Forms.Button
$uninstall.Text = "Uninstall"
$uninstall.Size = New-Object System.Drawing.Size(120,40)
$uninstall.Location = New-Object System.Drawing.Size(270,250)
$uninstall.FlatStyle = "0"
$uninstall.FlatAppearance.BorderSize = "0"
$uninstall.BackColor = $theme[2]

# If ADB is found, update buttons & show uninstall option
$uninstall.Hide()
if (Get-Command adb -ErrorAction SilentlyContinue) {
    $location = "$env:PATH".split(";") | Select-String "platform-tools"
    Write-Host "ADB Found at: $location"
    $install.Text = "Update"
    $filepath.Text = "$location"
    $uninstall.Show()
}

# Select installation folder in filepicker & set in textbox
$browse.Add_Click{
    $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    [void]$FileBrowser.ShowDialog()
    if ($FileBrowser.SelectedPath) { $filepath.Text = $FileBrowser.SelectedPath }
}

# Install ADB to selected folder & make environment variable. If checkbox is checked, install Universal ADB Drivers
$install.Add_Click{
    Write-Host "Backing Up PATH Environment Variable to PATH_BACKUP"
    [Environment]::SetEnvironmentVariable("PATH_BACKUP","$env:PATH","User")
    install_adb $filepath.Text
    if ($adbdrivers.Checked) { install_adbdrivers }
}

# Delete ADB & drivers (if present) then, set environment variable to null
$uninstall.Add_Click{
    uninstall_adb
    if (Get-Package -Name "Universal Adb Driver" -ErrorAction SilentlyContinue) { uninstall_adbdrivers }
}

$window.Controls.AddRange(@($description,$filepath,$adbdrivers,$browse,$install,$uninstall))
$window.ShowDialog()
