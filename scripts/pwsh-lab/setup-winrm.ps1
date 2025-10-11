# scripts/pwsh-lab/setup-winrm.ps1
$Log = 'C:\Windows\Temp\setup-winrm.log'
"[$(Get-Date -Format o)] setup-winrm.ps1 starting" | Out-File -FilePath $Log -Append -Encoding UTF8

try {
    # 1)  Private network (otherwise firewall block  WinRM)
    $nics = Get-NetAdapter | Where-Object Status -eq 'Up'
    foreach ($nic in $nics) {
        Set-NetConnectionProfile -InterfaceAlias $nic.Name -NetworkCategory Private -ErrorAction SilentlyContinue
    }
    "[$(Get-Date -Format o)] Network set to Private" | Out-File $Log -Append

    # 2) Enable PSRemoting (crée listener par défaut si absent)
    Enable-PSRemoting -Force
    "[$(Get-Date -Format o)] Enable-PSRemoting done" | Out-File $Log -Append

    # 3) Allow  Basic + Unencrypted  (packer wait this if no SSL)
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
    "[$(Get-Date -Format o)] WSMan Basic+AllowUnencrypted enabled" | Out-File $Log -Append

    # 4) Make  listener HTTP on all interfaces
    $listener = (dir WSMan:\localhost\Listener 2>$null | Where-Object Keys -match 'Transport=HTTP')
    if (-not $listener) {
        winrm create winrm/config/Listener?Address=*+Transport=HTTP
        "[$(Get-Date -Format o)] HTTP listener created" | Out-File $Log -Append
    } else {
        "[$(Get-Date -Format o)] HTTP listener already present" | Out-File $Log -Append
    }

    # 5) Firewall (profils Private & Public par sécurité)
    $rules = @(
        'Windows Remote Management (HTTP-In)'
    )
    foreach ($r in $rules) {
        Get-NetFirewallRule -DisplayName $r -ErrorAction SilentlyContinue |
            Set-NetFirewallRule -Profile Domain,Private,Public -Enabled True -Action Allow
    }
    "[$(Get-Date -Format o)] Firewall rules enabled" | Out-File $Log -Append

    # 6) WinRM Service
    Set-Service -Name WinRM -StartupType Automatic
    (Get-Service WinRM).DelayedAutoStart = $true
    Start-Service -Name WinRM
    "[$(Get-Date -Format o)] WinRM service started" | Out-File $Log -Append

    "[$(Get-Date -Format o)] setup-winrm.ps1 SUCCESS" | Out-File $Log -Append
}
catch {
    "[$(Get-Date -Format o)] ERROR: $($_.Exception.Message)" | Out-File $Log -Append
    throw
}
