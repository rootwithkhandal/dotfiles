Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll

# Require admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

# Disable Unused/Risky Services
# Remote Registry — no legit reason to have this on for a laptop
Set-Service -Name RemoteRegistry -StartupType Disabled -Status Stopped

# SMBv1 — legacy, exploitable (EternalBlue-class stuff)
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Fax service
Set-Service -Name Fax -StartupType Disabled -Status Stopped -ErrorAction SilentlyContinue

# Print Spooler — disable ONLY if you don't print (PrintNightmare-class vulns live here)
# Set-Service -Name Spooler -StartupType Disabled -Status Stopped

# WMPNetworkSvc (Windows Media Player Network Sharing) — rarely needed
Set-Service -Name WMPNetworkSvc -StartupType Disabled -Status Stopped -ErrorAction SilentlyContinue

# Downloaded Maps Manager
Set-Service -Name MapsBroker -StartupType Disabled -Status Stopped -ErrorAction SilentlyContinue

# Check SMBv1 status
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol

# Disable SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Disable LLMNR via Group Policy or registry
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" `
    -Name "EnableMulticast" -Value 0 -Type DWORD

# Disable NetBIOS on all adapters (via WMI)
$adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2) # 2 = Disable NetBIOS over TCP/IP
}

# Via registry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDriveTypeAutoRun" -Value 255 -Type DWORD
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDriveTypeAutoRun" -Value 255 -Type DWORD
# Disable Remote Desktop (if not needed)
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 1 -Type DWORD

# registry import function
function Import-RegistryFiles {
    param([string]$Mode)

    Write-Section "Importing registry files: $Mode"

    Invoke-Step "registry" $Mode {
        $registryDir = Join-Path $DotfilesDir "windows\registry\$Mode"
        if (-not (Test-Path -LiteralPath $registryDir -PathType Container)) {
            throw "Registry folder was not found: $registryDir"
        }

        Get-ChildItem -LiteralPath $registryDir -Filter "*.reg" | Sort-Object Name | ForEach-Object {
            Write-Host "Importing $($_.Name)"
            Invoke-Native "reg" @("import", $_.FullName)
        }
    }
}

# custom registry entries for user and system registry
# memory integrity / HVCI
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -Type DWord -Force


# attack surface reduction rules
# Block Office apps from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Enabled

# Block Office apps from injecting code into other processes
Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 -AttackSurfaceReductionRules_Actions Enabled

# Block execution of potentially obfuscated scripts
Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Enabled

# Block JavaScript/VBScript from launching downloaded executable content
Add-MpPreference -AttackSurfaceReductionRules_Ids D3E037E1-3EB8-44C8-A917-57927947596D -AttackSurfaceReductionRules_Actions Enabled

# Block Office communication apps from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids 26190899-1602-49E8-8B27-EB1D0A1CE869 -AttackSurfaceReductionRules_Actions Enabled

# Block credential stealing from LSASS
Add-MpPreference -AttackSurfaceReductionRules_Ids 9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2 -AttackSurfaceReductionRules_Actions Enabled

# Block executable files from running unless they meet prevalence/age/trusted list criteria
Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-CD74-433A-B99E-2ECDC07BFC25 -AttackSurfaceReductionRules_Actions Enabled

# Use advanced protection against ransomware
Add-MpPreference -AttackSurfaceReductionRules_Ids C1DB55AB-C21A-4637-BB3F-A12568109D35 -AttackSurfaceReductionRules_Actions Enabled

# Check what's applied
Get-MpPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids



$Log   = @()
$Fails = 0

function Install-Winget {
    param([string]$Id, [string]$Label = $Id)
    try {
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --no-upgrade -e
        $script:Log += "[OK]  [winget] $Label"
    } catch {
        $script:Log += "[FAIL][winget] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

function Install-Choco {
    param([string]$Id, [string]$Label = $Id)
    try {
        choco install $Id -y --no-progress 2>&1 | Out-Null
        $script:Log += "[OK]  [choco ] $Label"
    } catch {
        $script:Log += "[FAIL][choco ] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

# Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed - skipping." -ForegroundColor Green
}

# Scoop (cannot install as Admin - must be done in a normal PowerShell window)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "SKIPPED: Scoop must be installed in a non-Admin PowerShell." -ForegroundColor Yellow
    Write-Host "  Run this in a normal PowerShell window:" -ForegroundColor Yellow
    Write-Host "  irm get.scoop.sh | iex" -ForegroundColor Yellow
    $Log += "[SKIP] Scoop - run 'irm get.scoop.sh | iex' in a non-Admin PowerShell"
} else {
    Write-Host "Scoop already installed - skipping." -ForegroundColor Green
    $Log += "[OK]  Scoop already present"
}

# Dev Tools
Write-Host "`nInstalling dev tools..." -ForegroundColor Cyan
Install-Winget "Microsoft.VisualStudioCode"      "VS Code"
Install-Winget "Microsoft.WindowsTerminal"       "Windows Terminal"
Install-Winget "Git.Git"                         "Git"
Install-Winget "GitHub.cli"                      "GitHub CLI"
Install-Winget "Python.Python.3.12"              "Python 3.12"
Install-Winget "OpenJS.NodeJS.LTS"               "Node.js LTS"
Install-Winget "GoLang.Go"                       "Go"
Install-Winget "Rustlang.Rustup"                 "Rust"
Install-Winget "Docker.DockerDesktop"            "Docker Desktop"
Install-Winget "JetBrains.Toolbox"               "JetBrains Toolbox"
winget install ajeetdsouza.zoxide
# winget install -e --id Xournal++.Xournal++
winget install jdx.mise
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
winget install -e Atuinsh.Atuin
# winget install sharkdp.bat
winget install JanDeDobbeleer.OhMyPosh --source winget

# Git Config
Write-Host "`nConfiguring Git..." -ForegroundColor Cyan
try {
    git config --global user.name  "Your Name"
    git config --global user.email "you@example.com"
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    $Log += "[OK]  Git global config applied"
} catch {
    $Log += "[FAIL] Git config - " + $_.Exception.Message
    $Fails++
}

# Node.js Extras
Write-Host "`nSetting up Node.js extras..." -ForegroundColor Cyan
try {
    npm install -g pnpm
    npm install -g yarn
    $Log += "[OK]  pnpm + yarn installed globally"
} catch {
    $Log += "[FAIL] Node global tools - " + $_.Exception.Message
    $Fails++
}

# Network & Recon
Write-Host "`nInstalling network/recon tools..." -ForegroundColor Cyan
Install-Winget "Nmap.Nmap"                       "Nmap"
Install-Winget "WiresharkFoundation.Wireshark"   "Wireshark"
Install-Choco  "masscan"                         "Masscan"
Install-Choco  "netcat"                          "Netcat"

# Security / Pentesting
Write-Host "`nInstalling security tools..." -ForegroundColor Cyan
Install-Winget "PortSwigger.BurpSuite.Community" "Burp Suite Community"
Install-Choco  "maltego"                         "Maltego"
Install-Choco  "metasploit"                      "Metasploit"
Install-Choco  "openvpn"                         "OpenVPN"

# WSL
Write-Host "`nSetting up WSL..." -ForegroundColor Cyan
try {
    wsl --install
    wsl --install -d kali-linux
    wsl --install -d Ubuntu
    wsl --update
    $Log += "[OK]  WSL + Kali + Ubuntu installed"
} catch {
    $Log += "[FAIL] WSL - " + $_.Exception.Message
    $Fails++
}


# -------------------------------------------------------------------
# 2. Install fonts and editor configurations
# -------------------------------------------------------------------
# Fonts
if (Test-Path "scripts/install-fonts.ps1") {
    Write-Host-Color "Installing fonts..." "Yellow"
    powershell -ExecutionPolicy Bypass -File "scripts/install-fonts.ps1" -Force
} else {
    Write-Host-Color "install-fonts.ps1 not found, skipping font installation." "Red"
}

# WezTerm configuration
if (Test-Path ".\wezterm\.wezterm.lua") {
    Write-Host-Color "Installing WezTerm configuration..." "Yellow"
    $weztermDest = Join-Path $HOME ".wezterm.lua"
    Copy-Item ".\wezterm\.wezterm.lua" $weztermDest -Force
    Write-Host "Done: $weztermDest" -ForegroundColor Green
} else {
    Write-Host-Color "WezTerm config not found, skipping." "Red"
}

# Neovim configuration
if (Test-Path ".\nvim") {
    Write-Host-Color "Installing Neovim configuration..." "Yellow"
    $nvimDest = Join-Path $env:LOCALAPPDATA "nvim"
    if (Test-Path $nvimDest) {
        Write-Host "Removing existing Neovim config at $nvimDest" -ForegroundColor Gray
        Remove-Item $nvimDest -Recurse -Force
    }
    Copy-Item ".\nvim" $nvimDest -Recurse -Force
    Write-Host "Done: $nvimDest" -ForegroundColor Green
} else {
    Write-Host-Color "Neovim config not found, skipping." "Red"
}

# VS Code configuration
if (Test-Path ".\Vscode\User\settings.json") {
    Write-Host-Color "Installing VS Code configuration..." "Yellow"
    $vscodeDestDir = Join-Path $env:APPDATA "Code\User"
    if (-not (Test-Path $vscodeDestDir)) {
        New-Item -ItemType Directory -Path $vscodeDestDir -Force | Out-Null
    }
    $vscodeDest = Join-Path $vscodeDestDir "settings.json"
    Copy-Item ".\Vscode\User\settings.json" $vscodeDest -Force
    Write-Host "Done: $vscodeDest" -ForegroundColor Green
} else {
    Write-Host-Color "VS Code config not found, skipping." "Red"
}

function Invoke-StowAll {
    param([string]$TargetDir)

    Write-Section "Stowing Windows dotfiles"

    Invoke-Step "stow" $TargetDir {
        if (-not (Get-Command stow -ErrorAction SilentlyContinue)) {
            throw "stow is required. Install GNU Stow for Windows before running this step."
        }

        $packageGlobs = @(
            "windows\assets\*",
            "windows\browser\*",
            "windows\editor\*",
            "windows\obsidian",
            "windows\security\*",
            "windows\shell",
            "windows\ssh",
            "windows\terminal\*",
            "windows\wallpaper",
            "windows\wsl"
        )

        foreach ($glob in $packageGlobs) {
            Get-ChildItem -Path (Join-Path $DotfilesDir $glob) -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -eq "windows-terminal") {
                    Write-Host "Skipping windows-terminal; import windows\terminal\windows-terminal\settings.json manually."
                    return
                }

                $packageDir = Split-Path -Parent $_.FullName
                $packageName = Split-Path -Leaf $_.FullName
                $relativePath = $_.FullName.Replace($DotfilesDir, "").TrimStart("\")

                Write-Host "Stowing $packageName from $relativePath"
                Invoke-Native "stow" @("-d", $packageDir, "-t", $TargetDir, $packageName)
            }
        }
    }
}


# firewall

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Set default inbound policy to Block
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow

# Block SMB from internet-facing interfaces (port 445)
New-NetFirewallRule -DisplayName "Block SMB Inbound" -Direction Inbound `
    -Protocol TCP -LocalPort 445 -Action Block -Profile Public

# Block RDP from untrusted networks
New-NetFirewallRule -DisplayName "Block RDP Public" -Direction Inbound `
    -Protocol TCP -LocalPort 3389 -Action Block -Profile Public

# Block WinRM from public (port 5985/5986)
New-NetFirewallRule -DisplayName "Block WinRM Public" -Direction Inbound `
    -Protocol TCP -LocalPort 5985,5986 -Action Block -Profile Public

Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow
Set-NetFirewallProfile -Profile Domain,Public,Private -LogBlocked True -LogAllowed True -LogMaxSizeKilobytes 32767 -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall.log"

# File & Printer sharing is a lateral movement vector — kill it
Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Set-NetFirewallRule -Enabled False

# RDP off unless you specifically need it
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Set-NetFirewallRule -Enabled

# Set all profiles to block inbound by default, allow outbound
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow

# Enable logging for dropped and allowed packets
Set-NetFirewallProfile -Profile Domain,Public,Private -LogBlocked True -LogAllowed True -LogMaxSizeKilobytes 32767 -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall.log"

# Disable File & Printer sharing inbound rules (common lateral movement vector)
Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Set-NetFirewallRule -Enabled False

# Block inbound RDP unless specifically needed
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Set-NetFirewallRule -Enabled

# List all enabled inbound rules
Get-NetFirewallRule -Direction Inbound -Enabled True |
    Select-Object DisplayName, Action, Profile | Sort-Object Action

# Find rules that allow everything (potentially dangerous)
Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True |
    Get-NetFirewallPortFilter | Where-Object {$_.LocalPort -eq "Any"}

Set-NetFirewallProfile -Profile Domain,Private,Public `
    -LogFileName "%systemroot%\system32\LogFiles\Firewall\pfirewall.log" `
    -LogMaxSizeKilobytes 32767 `
    -LogBlocked True `
    -LogAllowed True


# Enable key audit categories
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable
auditpol /set /category:"Privilege Use" /success:enable /failure:enable
auditpol /set /category:"Process Creation" /success:enable /failure:enable
auditpol /set /category:"System" /success:enable /failure:enable
auditpol /set /category:"DS Access" /success:enable /failure:enable

# Verify current settings
auditpol /get /category:*


# Set Security log to 1 GB
wevtutil sl Security /ms:1073741824

# Set System log to 256 MB
wevtutil sl System /ms:268435456

# Set Application log to 256 MB
wevtutil sl Application /ms:268435456

# PowerShell Operational log - 256 MB
wevtutil sl "Microsoft-Windows-PowerShell/Operational" /ms:268435456 /e:true


# Via registry (enables command line in Event ID 4688)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" `
    -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -Type DWORD


Get-MpComputerStatus | Select-Object AMServiceEnabled, AntispywareEnabled, `
    AntivirusEnabled, RealTimeProtectionEnabled, NISEnabled

# Enable real-time protection
Set-MpPreference -DisableRealtimeMonitoring $false

# Enable cloud-delivered protection
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendAllSamples

# Enable network protection (blocks malicious domains/IPs)
Set-MpPreference -EnableNetworkProtection Enabled

# Enable behavior monitoring
Set-MpPreference -DisableBehaviorMonitoring $false

# Enable PUA (Potentially Unwanted Applications) protection
Set-MpPreference -PUAProtection Enabled


# Block Office macros from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A `
    -AttackSurfaceReductionRules_Actions Enabled

# Block credential stealing from LSASS
Add-MpPreference -AttackSurfaceReductionRules_Ids 9E6C4E1F-7D60-472F-BA1A-A39EF669E4B0 `
    -AttackSurfaceReductionRules_Actions Enabled

# Block execution of potentially obfuscated scripts
Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC `
    -AttackSurfaceReductionRules_Actions Enabled

# Block Office from injecting code into other processes
Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 `
    -AttackSurfaceReductionRules_Actions Enabled

# Block Win32 API calls from Office macros
Add-MpPreference -AttackSurfaceReductionRules_Ids 92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B `
    -AttackSurfaceReductionRules_Actions Enabled

# Block executable content from email/webmail
Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 `
    -AttackSurfaceReductionRules_Actions Enabled

# Verify ASR rules
Get-MpPreference | Select-Object AttackSurfaceReductionRules_Ids, AttackSurfaceReductionRules_Actions

Update-MpSignature


# Enable Script Block Logging (logs all executed script blocks)
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
New-Item -Path $path -Force
Set-ItemProperty -Path $path -Name "EnableScriptBlockLogging" -Value 1

# Enable Module Logging (logs pipeline execution)
$path2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
New-Item -Path $path2 -Force
Set-ItemProperty -Path $path2 -Name "EnableModuleLogging" -Value 1
New-Item -Path "$path2\ModuleNames" -Force
Set-ItemProperty -Path "$path2\ModuleNames" -Name "*" -Value "*"

# Enable Transcription (saves full session transcripts)
$path3 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"
New-Item -Path $path3 -Force
Set-ItemProperty -Path $path3 -Name "EnableTranscripting" -Value 1
Set-ItemProperty -Path $path3 -Name "OutputDirectory" -Value "C:\PSTranscripts"
Set-ItemProperty -Path $path3 -Name "EnableInvocationHeader" -Value 1


# Disable PowerShell v2 engine
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
# Or more restrictive:
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine

# Generate default rules (allow Windows and Program Files)
$policy = Get-AppLockerPolicy -Effective
# Use GUI: gpedit.msc → Computer Configuration → Windows Settings → Security Settings → Application Control Policies → AppLocker

$rule = New-Object Microsoft.Security.ApplicationId.PolicyManagement.PolicyModel.FilePathRule
# Use GPO/GUI for production; PowerShell AppLocker cmdlets for scripting
# Get-AppLockerPolicy, Set-AppLockerPolicy, New-AppLockerPolicy

# Check what WOULD be blocked
Get-AppLockerPolicy -Effective | Test-AppLockerPolicy -Path "C:\path\to\app.exe" -User Everyone

# Enable via registry
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
New-Item -Path $path -Force
Set-ItemProperty -Path $path -Name "EnableVirtualizationBasedSecurity" -Value 1
Set-ItemProperty -Path $path -Name "RequirePlatformSecurityFeatures" -Value 1

$credPath = "HKLM:\SYSTEM\CurrentControlSet\Control\LSA"
Set-ItemProperty -Path $credPath -Name "LsaCfgFlags" -Value 1

# Verify
Get-WmiObject -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard |
    Select-Object SecurityServicesRunning

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "RunAsPPL" -Value 1 -Type DWORD

# Verify (requires reboot)
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL"


Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -Name "UseLogonCredential" -Value 0 -Type DWORD

# Restrict NTLM authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" `
    -Name "RestrictSendingNTLMTraffic" -Value 2 -Type DWORD

# Audit NTLM usage first
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" `
    -Name "AuditReceivingNTLMTraffic" -Value 2 -Type DWORD

# Limit cached domain credentials (reduce lateral movement potential)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -Name "CachedLogonsCount" -Value 0 -Type String

# Monitor DNS cache for suspicious entries
Get-DnsClientCache | Where-Object {$_.Entry -notmatch "microsoft|windows|apple|google"} |
    Select-Object Entry, Data, TTL

# Enable DNS client logging
wevtutil sl "Microsoft-Windows-DNS-Client/Operational" /e:true /ms:268435456

# Compare against known good baseline
Get-NetTCPConnection -State Listen |
    Select-Object LocalAddress, LocalPort, OwningProcess |
    Sort-Object LocalPort


# Enable Developer Mode
# Settings → Privacy & Security → For Developers → Developer Mode → ON

# Enable long path support (many tools need this)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force


# Create the full structure automatically
$base = "C:\bugbounty"
@(
    "tools", "wordlists", "payloads", "reports",
    "programs\hackerone", "programs\bugcrowd",
    "programs\intigriti", "programs\yeswehack"
) | ForEach-Object {
    New-Item -ItemType Directory -Path "$base\$_" -Force | Out-Null
}
Write-Host "Folder structure created at $base" -ForegroundColor Green



# Chocolatey (run as Admin)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Scoop (user-level, no admin required)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras



winget install Python.Python.3.12
python -m pip install --upgrade pip
winget install GoLang.Go

winget install CoreyButler.NVMforWindows
winget install RubyInstallerTeam.RubyWithDevKit.3.3
winget install Git.Git
git config --global user.name  "Hunter"
git config --global user.email "hunter@lab.local"
pip install requests httpx beautifulsoup4 lxml dnspython \
    shodan censys trufflehog
winget install Microsoft.WindowsTerminal
winget install Microsoft.PowerShell

winget install JanDeDobbeleer.OhMyPosh
oh-my-posh font install   # Install a Nerd Font for icons

# Add to $PROFILE:
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

# theHarvester — emails, subdomains, IPs from public sources
pip install theHarvester
theHarvester -d target.com -b all -l 500

# Amass — comprehensive attack surface mapping
go install -v github.com/owasp-amass/amass/v4/...@master@latest
# amass enum -passive -d target.com -o amass_passive.txt
# amass intel -whois -d target.com

# Shodan CLI — internet-wide exposed asset discovery
pip install shodan
# shodan init <YOUR_API_KEY>
# shodan search "org:TargetCompany" --fields ip_str,port,org,hostnames
# shodan host <ip_address>

pip install dnsrecon
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

# Trufflehog — find secrets in Git history
pip install trufflehog
# trufflehog github --org=targetcompany
# trufflehog git https://github.com/targetcompany/repo.git

# Gitleaks — scan repos for secrets
go install github.com/gitleaks/gitleaks/v8@latest
# gitleaks detect --source . -v
# gitleaks detect --source /path/to/repo \
#     --report-format json --report-path leaks.json

go install github.com/tomnomnom/waybackurls@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/d3mondev/puredns/v2@latest
curl -s https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
    -o resolvers.txt

go install github.com/OJ/gobuster/v3@latest

go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

go install github.com/PentestPad/subzy@latest
go install github.com/haccer/subjack@latest

winget install PortSwigger.BurpSuite.Community
go install github.com/ffuf/ffuf/v2@latest
winget install epi052.feroxbuster

go install github.com/hahwul/dalfox/v2@latest
pip install sqlmap

go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
choco install nmap -y
choco install nikto -y

gem install whatweb
go install github.com/projectdiscovery/katana/cmd/katana@latest
winget install Postman.Postman
pip install inql
pip install

git clone https://github.com/swisskyrepo/PayloadsAllTheThings \
    C:\bugbounty\payloads\PayloadsAllTheThings

go install github.com/tomnomnom/gf@latest
mkdir -p ~/.gf

# Install community patterns
git clone https://github.com/1ndianl33t/Gf-Patterns ~/.gf


winget install Obsidian.Obsidian
winget install Mozilla.Firefox

"github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/projectdiscovery/katana/cmd/katana@latest"
    "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
    "github.com/tomnomnom/assetfinder@latest"
    "github.com/tomnomnom/waybackurls@latest"
    "github.com/tomnomnom/gf@latest"
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/hakluke/hakrawler@latest"
    "github.com/ffuf/ffuf/v2@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/sensepost/gowitness@latest"
    "github.com/OJ/gobuster/v3@latest"
    "github.com/d3mondev/puredns/v2@latest"
    "github.com/gitleaks/gitleaks/v8@latest"
    "github.com/PentestPad/subzy@latest"
    "github.com/haccer/subjack@latest"

mv keys.env C:\bugbounty\keys.env
source C:\bugbounty\keys.env



# Disable Game Bar (can interfere with some dev tools)
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" `
    -Name "AppCaptureEnabled" -Value 0

winget upgrade --all
# Add useful buckets
scoop bucket add extras
scoop bucket add java
scoop bucket add versions
scoop bucket add nerd-fonts


Install-Module -Name PSReadLine      -Force -SkipPublisherCheck  # Better readline
Install-Module -Name Terminal-Icons  -Force                       # File icons in terminal
Install-Module -Name z               -Force                       # Fuzzy directory jumping
Install-Module -Name posh-git        -Force                       # Git info in prompt
Install-Module -Name PSFzf           -Force                       # Fuzzy finder integration



# Identity
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"

# Default branch name
git config --global init.defaultBranch main

# Default editor (VS Code)
git config --global core.editor "code --wait"

# Diff tool (VS Code)
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
git config --global merge.tool vscode

# Line endings (Windows → Linux compatibility)
git config --global core.autocrlf true

# Credential manager (ships with Git for Windows)
git config --global credential.helper manager

# Useful aliases
git config --global alias.st     status
git config --global alias.co     checkout
git config --global alias.br     branch
git config --global alias.lg     "log --oneline --graph --decorate --all"
git config --global alias.undo   "reset HEAD~1 --mixed"
git config --global alias.wip    "commit -am 'WIP'"

# Pull strategy
git config --global pull.rebase false

# Show full config
git config --list

winget install Python.Python.3.12
# Upgrade pip
python -m pip install --upgrade pip

# Essential global tools
pip install virtualenv pipenv poetry black flake8 mypy ipython
winget install CoreyButler.NVMforWindows


winget install GoLang.Go

# Verify
go version

# Set GOPATH (add $HOME\go\bin to PATH)
$env:GOPATH = "$HOME\go"

# Essential tools
go install golang.org/x/tools/gopls@latest          # Language server
go install github.com/go-delve/delve/cmd/dlv@latest  # Debugger
go install github.com/cosmtrek/air@latest             # Live reload
go install golang.org/x/tools/cmd/goimports@latest    # Auto imports

# New module
mkdir myproject && cd myproject
go mod init github.com/username/myproject
winget install Rustlang.Rustup
# Install stable toolchain
rustup install stable
rustup default stable

# Verify
rustc --version
cargo --version

# Useful components
rustup component add rustfmt clippy rust-analyzer

# Useful cargo tools
cargo install cargo-watch    # Auto-rebuild on file change
cargo install cargo-edit     # cargo add / rm / upgrade
cargo install cargo-audit    # Dependency security audit

winget install Neovim.Neovim

winget install Docker.DockerDesktop
winget install Postman.Postman
# CLI version
pip install httpie

# Desktop app
winget install HTTPie.HTTPie

# Install browsers
winget install Google.Chrome
winget install Mozilla.Firefox

# Figma
winget install Figma.Figma

# Color picker (via PowerToys)
winget install Microsoft.PowerToys   # Win+Shift+C to pick any color on screen

winget install ngrok.ngrok


# Make (via Scoop — works on Windows)
scoop install make

# Just (modern make alternative)
scoop install just
# Create justfile with recipes
just build
just test
just deploy

# npm scripts (for Node.js projects) — define in package.json "scripts"

pip install ansible


# Install via Scoop
scoop install ripgrep   # rg — fast grep
scoop install fd        # fd — fast find
scoop install bat       # bat — cat with syntax highlighting
scoop install delta     # delta — better git diffs
scoop install fzf       # fzf — fuzzy finder
scoop install jq        # jq — JSON processor
scoop install yq        # yq — YAML/JSON/XML processor
scoop install hyperfine # hyperfine — command benchmarking
scoop install tokei     # tokei — code line counter


# Obsidian — local-first markdown, great for dev knowledge base
winget install Obsidian.Obsidian

# Notion — web-based, great for team docs
winget install Notion.Notion

# Install Remote - SSH (included in Remote Development pack)
code --install-extension ms-vscode-remote.remote-ssh

# Connect: Ctrl+Shift+P → "Remote-SSH: Connect to Host"
# Then select a host from your ~/.ssh/config
# VS Code installs its server on the remote and opens a full IDE session

# Symlink config files into dotfiles
New-Item -ItemType SymbolicLink -Path $PROFILE `
    -Target "$HOME\dotfiles\powershell\profile.ps1"
New-Item -ItemType SymbolicLink -Path "$HOME\.gitconfig" `
    -Target "$HOME\dotfiles\git\.gitconfig"


# bootstrap.ps1 — run once on a fresh Windows install

Write-Host "Bootstrapping dev environment..." -ForegroundColor Cyan

# Enable long paths
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" `
    /v LongPathsEnabled /t REG_DWORD /d 1 /f

# Package managers
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add extras

# Core apps
$apps = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Docker.DockerDesktop",
    "JanDeDobbeleer.OhMyPosh",
    "Python.Python.3.12",
    "GoLang.Go",
    "Microsoft.DotNet.SDK.8",
    "CoreyButler.NVMforWindows",
    "GitHub.cli",
    "Postman.Postman",
    "Microsoft.PowerToys",
    "voidtools.Everything",
    "TablePlus.TablePlus"
)
foreach ($app in $apps) {
    winget install $app --accept-package-agreements --accept-source-agreements -e
}

# CLI tools
scoop install ripgrep fd bat fzf jq delta

# WSL2
wsl --install -d Ubuntu-22.04

# Git config
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global core.autocrlf true

# VS Code extensions
$extensions = @(
    "ms-vscode-remote.vscode-remote-extensionpack", "eamodio.gitlens", "esbenp.prettier-vscode", "ms-azuretools.vscode-docker", "GitHub.github-vscode-theme", "eamodio.gitlens", "github.copilot", "github.copilot-chat", "ms-vscode-remote.remote-ssh", "ms-vscode-remote.remote-containers", "ms-vscode.remote-explorer", "ms-vscode.remote-server", "gruntfuggly.todo-tree", "aaron-bond.better-comments", "usernamehw.errorlens", "wmaurer.change-case", "ms-python.python", "ms-python.black-formatter", "ms-python.debugpy", "ms-toolsai.jupyter", "ms-toolsai.jupyter-keymap", "ms-toolsai.jupyter-renderers", "esbenp.prettier-vscode", "dbaeumer.vscode-eslint", "xabikos.javascriptsnippets", "pranaygp.vscode-css-peek", "formulahendry.auto-close-tag", "formulahendry.auto-rename-tag", "zhuangtongfa.material-theme", "juanblanco.solidity", "nomicfoundation.hardhat-solidity", "tintinweb.solidity-visual-auditor", "tintinweb.vscode-solidity-flattener", "tintinweb.vscode-solidity-metrics", "tintinweb.vscode-security-auditor", "infosec.vscode-nmap", "ms-azuretools.vscode-docker", "muteki.vscode-pcap", "spmeesseman.vscode-taskexplorer", "githyanki.debugtron", "kakumei.jsontools", "sandcastle.vscode-open-in-burp", "vscode-icons-team.vscode-icons", "ms-vscode.powershell", "ms-azuretools.vscode-azurefunctions", "ms-kubernetes-tools.vscode-kubernetes-tools", "ms-vscode.azure-repos", "ionutvmi.path-autocomplete", "bencoleman.armview", "elastic.elastic-vscode", "redhat.vscode-yaml", "foxundermoon.shell-format", "golang.go", "bmewburn.vscode-intelephense-client", "rebornix.ruby", "timonwong.shellcheck", "mads-hartmann.bash-ide-vscode", "shakram02.bash-beautify", "ms-azuretools.vscode-docker", "hashicorp.terraform", "redhat.vscode-yaml", "oderwat.indent-rainbow", "pkief.material-icon-theme", "naumovs.color-highlight", "akamud.vscode-theme-onedark", "spywhere.guides", "glassit.alpha", "enkia.tokyo-night", "catppuccin.catppuccin-vsc", "ms-vscode.cpptools-extension-pack", "ms-python.vscode-pylance", "ms-vscode.cmake-tools", "vscode.git", "PKief.material-icon-theme"
)
foreach ($ext in $extensions) { code --install-extension $ext }

Write-Host "Done! Restart your machine to complete setup." -ForegroundColor Green




# Summary
Write-Host "`n=============================================" -ForegroundColor White
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
$Log | ForEach-Object { Write-Host $_ }
Write-Host "---------------------------------------------"
if ($Fails -eq 0) {
    Write-Host "All done - no failures!" -ForegroundColor Green
} else {
    Write-Host "Done with $Fails failure(s). Check the log above." -ForegroundColor Yellow
}
Write-Host "NOTE: Reboot recommended to finalise Docker, WSL, and Rust." -ForegroundColor Cyan
