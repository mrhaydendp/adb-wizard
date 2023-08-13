# If not Admin, run with Admin privileges 
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Set application theme based on AppsUseLightTheme prefrence
$theme = @("#ffffff","#202020","#323232")
if (Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"){
    $theme = @("#292929","#f3f3f3","#fbfbfb")
}

# GUI specs
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "ADB Wizard"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Point(550,300)
$form.ForeColor = $theme[0]
$form.BackColor = $theme[1]

# Instructional text
$description = New-Object System.Windows.Forms.Label
$description.Text = "Welcome to ADB Wizard, a graphical tool designed to effortlessly install ADB (Android Debug Bridge) system-wide on Windows. Please Select an installation directory for ADB."
$description.Size = New-Object System.Drawing.Size(400,40)
$description.Location = New-Object System.Drawing.Size(10,20)
$description.ForeColor = $theme[0]
$form.Controls.Add($description)

# Buttons
$filepath = New-Object System.Windows.Forms.Textbox
$filepath.Text = ("$HOME")
$filepath.Size = New-Object System.Drawing.Size(400,40)
$filepath.Location = New-Object System.Drawing.Size(140,130)
$filepath.ForeColor = $theme[0]
$filepath.BackColor = $theme[2]
$form.Controls.Add($filepath)

$adbdrivers = New-Object System.Windows.Forms.CheckBox
$adbdrivers.Text = "Install Universal ADB Drivers (Optional)"
$adbdrivers.Size = New-Object System.Drawing.Size(220,20)
$adbdrivers.Location = New-Object System.Drawing.Size(140,155)
$adbdrivers.FlatStyle = "0"
$adbdrivers.FlatAppearance.BorderSize = "0"
$adbdrivers.ForeColor = $theme[0]
$form.Controls.Add($adbdrivers)

$browse = New-Object System.Windows.Forms.Button
$browse.Text = "Browse"
$browse.Size = New-Object System.Drawing.Size(120,40)
$browse.Location = New-Object System.Drawing.Size(10,120)
$browse.FlatStyle = "0"
$browse.FlatAppearance.BorderSize = "0"
$browse.BackColor = $theme[2]
$form.Controls.Add($browse)

$install = New-Object System.Windows.Forms.Button
$install.Text = "Install"
$install.Size = New-Object System.Drawing.Size(120,40)
$install.Location = New-Object System.Drawing.Size(410,250)
$install.FlatStyle = "0"
$install.FlatAppearance.BorderSize = "0"
$install.BackColor = $theme[2]
$form.Controls.Add($install)

$uninstall = New-Object System.Windows.Forms.Button
$uninstall.Text = "Uninstall"
$uninstall.Size = New-Object System.Drawing.Size(120,40)
$uninstall.Location = New-Object System.Drawing.Size(270,250)
$uninstall.FlatStyle = "0"
$uninstall.FlatAppearance.BorderSize = "0"
$uninstall.BackColor = $theme[2]
$form.Controls.Add($uninstall)

# If ADB is found, update buttons & $path variable
try{
    (adb --version | Select-String "[A-Z]:(.*?)platform-tools").Matches.Value -replace "\\platform-tools" | % {
        Write-Host "ADB Found at:" "'$_\platform-tools'"
        $install.Text = "Update"
        $filepath.Text = "$_"
    }
} catch { $uninstall.Location = New-Object System.Drawing.Size(500,500) }
$path = $filepath.Text

# Select installation folder in filepicker & set in textbox
$browse.Add_Click{
    $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    [void]$FileBrowser.ShowDialog()
    if ($FileBrowser.SelectedPath){
        $filepath.Text  = $FileBrowser.SelectedPath
    }
}

# Install ADB to selected folder & make environment variable. If checkbox is checked, install Universal ADB Drivers
$install.Add_Click{
    if ($adbdrivers.Checked){
        Write-Host "`nInstalling Universal ADB Driver: https://adb.clockworkmod.com/"
        Start-BitsTransfer "https://github.com/koush/adb.clockworkmod.com/releases/latest/download/UniversalAdbDriverSetup.msi"; .\UniversalAdbDriverSetup.msi /passive
        while (!(Get-Package -Name "Universal Adb Driver" -ErrorAction SilentlyContinue)){}
        Write-Host "Successfully Installed Universal ADB Driver"
        Remove-Item .\UniversalAdbDriverSetup.msi
    }
    Write-Host "`nInstalling ADB (Android Debug Bridge): https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    Start-BitsTransfer "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -Destination "$path"
    Expand-Archive -Verbose -Force "$path\platform-tools-latest-windows.zip" -Destination "$path"; Remove-Item "$path\platform-tools-latest-windows.zip"
    [Environment]::SetEnvironmentVariable("Path", "$Env:PATH" + "$path\platform-tools", "User")
    if (Test-Path "$path\platform-tools"){
        Write-Host "Successfully Installed ADB to:" "'$path\platform-tools'"
        Write-Host "`nNote: You may need to restart the PowerShell window to access ADB"
        $install.Text = "Update"
        $uninstall.Location = New-Object System.Drawing.Size(270,250)
    }
}

# Delete ADB & drivers (if present) then, set environment variable to null
$uninstall.Add_Click{
    Write-Host "`nRemoving ADB From:" "'$path\platform-tools'"
    Remove-Item -Verbose -Recurse "$path\platform-tools"
    if (Test-Path "C:\Program Files (x86)\ClockworkMod\Universal Adb Driver"){
        Write-Host "Removing Universal ADB Driver"
        Get-Package -Name "Universal Adb Driver" | Uninstall-Package
        Remove-Item -Verbose -Recurse "C:\Program Files (x86)\ClockworkMod"
    }
    Write-Host "Removing ADB Environment Variable"
    [Environment]::SetEnvironmentVariable("Path", "$null", "User")
    $uninstall.Location = New-Object System.Drawing.Size(500,500)
    $install.Text = "Install"
    Write-Host "Successfully Removed ADB & Environment Variable"
}

$form.ShowDialog()
