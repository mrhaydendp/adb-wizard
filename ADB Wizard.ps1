# If not Admin, run with Admin privileges 
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
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

$exit = New-Object System.Windows.Forms.Button
$exit.Text = "Exit"
$exit.Size = New-Object System.Drawing.Size(120,40)
$exit.Location = New-Object System.Drawing.Size(270,250)
$exit.FlatStyle = "0"
$exit.FlatAppearance.BorderSize = "0"
$exit.BackColor = $theme[2]
$form.Controls.Add($exit)

# If ADB is found, update buttons
try{
    (adb --version | Select-String "[A-Z]:(.*?)platform-tools").Matches.Value -replace "\\platform-tools" | % {
        Write-Host "ADB Found at:" "'$_\platform-tools'"
        $install.Text = "Update"
        $filepath.Text = "$_"
    }
} catch {}

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
    $path = $filepath.Text
    Write-Host "Installing ADB (Android Debug Bridge): https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
    Start-BitsTransfer "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -Destination "$path"
    Expand-Archive -Verbose -Force "$path\platform-tools-latest-windows.zip" -Destination "$path"; Remove-Item "$path\platform-tools-latest-windows.zip"
    [Environment]::SetEnvironmentVariable("PATH", $Env:PATH + ";$path\platform-tools", [EnvironmentVariableTarget]::Machine)
    if (Test-Path "$path\platform-tools"){
        Write-Host "Successfully Installed ADB to:" "'$path\platform-tools'"
        $install.Text = "Update"
    }
    if ($adbdrivers.Checked){
        Write-Host "Installing Universal ADB Driver: https://adb.clockworkmod.com/"
        Start-BitsTransfer "https://github.com/koush/adb.clockworkmod.com/releases/latest/download/UniversalAdbDriverSetup.msi"; .\UniversalAdbDriverSetup.msi /passive
        if (Test-Path "C:\Program Files (x86)\ClockworkMod\Universal Adb Driver"){
            Write-Host "Successfully Installed Universal ADB Drivers"
        }
    }

}

# Exit application
$exit.Add_Click{
    $form.Close()
}

$form.ShowDialog()
