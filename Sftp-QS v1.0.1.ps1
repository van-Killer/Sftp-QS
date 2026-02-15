Write-Host "       _________         ____    ____" -ForegroundColor White 
Write-Host "      / __/ _/ /____    / __ \  / __/" -ForegroundColor White 
Write-Host "     _\ \/ _/ __/ _ \  / /_/ / _\ \  " -ForegroundColor White 
Write-Host "    /___/_/ \__/ .__/  \___\_\/___/  " -ForegroundColor White 
Write-Host "              /_/                    " -ForegroundColor White 
Write-Host "                 v1.0.0.1            " -ForegroundColor White 
Write-Host ""
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
 if ($sshServer.State -eq 'Installed') {
    Write-Host ">>> OpenSSH.Server is already installed." -ForegroundColor Green
 } else {
    Write-Host ">>> OpenSSH.Server is not installed." -ForegroundColor Red
    Write-Host ">>> Installing OpenSSH.Server." -ForegroundColor White
    Add-WindowsCapability -Online -Name OpenSSH.Server        
    Write-Host ">>> OpenSSH.Server installed successfully." -ForegroundColor Green
}

Write-Host ">>> Starting sshd service." -ForegroundColor White
if ((Get-Service sshd).Status -eq 'Running') {
    write-Host ">>> sshd service is alreadyrunning." -ForegroundColor Green
} else {
    Write-Host ">>> sshd service is not running." -ForegroundColor Red
    Write-Host ">>> Attempting to start sshd service..." -ForegroundColor White
    Start-Service sshd
    Write-Host ">>> sshd service started successfully." -ForegroundColor Green
}

Write-Host ">>> Setting sshd service to start automatically." -ForegroundColor White
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host ">>> sshd service startup type set to Automatic." -ForegroundColor Green
Write-Host ">>> Checking if firewall rule 'OpenSSH-Server-In-TCP' exists." -ForegroundColor White
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {    
    Write-Host ">>> Firewall Rule 'OpenSSH-Server-In-TCP' does not exist." -ForegroundColor Red
    write-Host ">>> Creating firewall rule 'OpenSSH-Server-In-TCP' to allow inbound TCP traffic on port 22." -ForegroundColor White
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host ">>> Firewall rule 'OpenSSH-Server-In-TCP' has been created." -ForegroundColor Green
} else {
    Write-Host ">>> Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists." -ForegroundColor Green
}


$createNewUser = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
$noCreateNewUser = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($createNewUser, $noCreateNewUser)
Write-Host ">>> Do you want to create a new local user account for SFTP access?" -ForegroundColor White
$result = $host.ui.PromptForChoice("","",$options, 1)
if ($result -eq 0) {
    Write-Host ">>> Creating a local user account for SFTP access." -ForegroundColor White
    $username=$(Write-Host "Enter a username for the SFTP client account (default: sftp-client):" -ForegroundColor White -NoNewLine; Read-Host)
    if ([string]::IsNullOrEmpty($username)) {
        $username = "sftp-client"
    }

    #$password=Read-Host "Enter a password for the SFTP client account (default: 12345678)" -AsSecureString -color White
    $password=$(Write-Host "Enter a password for the SFTP client account (default: 12345678):" -ForegroundColor White -NoNewLine; Read-Host -AsSecureString)
    if ($password.Length -eq 0) {
        $password = ConvertTo-SecureString "12345678" -AsPlainText -Force
    }
    New-LocalUser -Name $username -Password $password
    Write-Host ">>> Local user account '$username' has been created with the specified password." -ForegroundColor Green
}

write-Host ">>> SFTP server setup is complete." 
write-Host ">>> You can now connect to this machine using an SFTP client with the local user login/password data." -ForegroundColor Green
Pause