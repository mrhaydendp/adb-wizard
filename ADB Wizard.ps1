# Run as Admin
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
	#Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Set Theme Based on AppsUseLightTheme Prefrence
$theme = @("#ffffff","#202020","#323232")
if (Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"){
    $theme = @("#292929","#f3f3f3","#fbfbfb")
}

# GUI Specs
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "ADB Wizard"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Point(550,300)
$form.ForeColor = $theme[0]
$form.BackColor = $theme[1]

$filepath = New-Object System.Windows.Forms.Textbox
$filepath.Text = ($HOME)
$filepath.Size = New-Object System.Drawing.Size(400,40)
$filepath.Location = New-Object System.Drawing.Size(140,150)
$filepath.ForeColor = $theme[0]
$filepath.BackColor = $theme[2]
$form.Controls.Add($filepath)

$browse = New-Object System.Windows.Forms.Button
$browse.Text = "Browse"
$browse.Size = New-Object System.Drawing.Size(120,40)
$browse.Location = New-Object System.Drawing.Size(10,140)
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

$form.ShowDialog()
