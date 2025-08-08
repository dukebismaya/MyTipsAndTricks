# Windows Command and PowerShell Tips & Tricks

**Notes:**
- Prefer PowerShell (PS) where possible. Many CMD commands have modern PS equivalents.
- Run PowerShell as Administrator when commands require elevated rights.
- Be careful with commands that reveal sensitive info (e.g., Wi‑Fi keys).
- Some commands may require specific modules or Windows features to be enabled.

---

## System Information & Diagnostics

### Basic System Info
CMD:
```cmd
systeminfo | more
```

PowerShell (faster to scan):
```powershell
Get-ComputerInfo | Select-Object OsName, OsVersion, CsSystemType, WindowsProductName, WindowsVersion, BiosSMBIOSBIOSVersion | Format-List
```

### System Uptime & Boot Info
Last boot time / uptime:
```powershell
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Get-Uptime
```

Boot configuration:
```cmd
bcdedit /enum
```

### Hardware Information
CPU details:
```powershell
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List
```

RAM information:
```powershell
Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, Capacity, Speed, Manufacturer | Format-Table -AutoSize
```

Motherboard info:
```powershell
Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, Version | Format-List
```

### Event Logs
Recent system errors:
```powershell
Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 10 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap
```

Application errors:
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2} -MaxEvents 10 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap
```

---

## Battery & Power Management

### Battery Report (fixed)
Generate to Desktop:
```cmd
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery_report.html"
start "" "%USERPROFILE%\Desktop\battery_report.html"
```

PowerShell version:
```powershell
powercfg /batteryreport /output "$env:USERPROFILE\Desktop\battery_report.html"
Start-Process "$env:USERPROFILE\Desktop\battery_report.html"
```

### Power Schemes
List power schemes:
```cmd
powercfg /list
```

Get current power scheme:
```cmd
powercfg /getactivescheme
```

Set high performance:
```cmd
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

### Sleep States
Check sleep states:
```cmd
powercfg /availablesleepstates
```

Disable hibernation:
```cmd
powercfg /hibernate off
```

---

## Network & Connectivity

### Ping and Connectivity
Continuous ping (CMD):
```cmd
ping google.com -t
```

PowerShell alternative with timing:
```powershell
Test-Connection -TargetName google.com -Continuous
```

Ping with specific packet size:
```cmd
ping google.com -l 1472
```

### Network Troubleshooting
Trace route:
```cmd
tracert google.com
```

Flush DNS cache:
```cmd
ipconfig /flushdns
```

Release and renew IP:
```cmd
ipconfig /release
ipconfig /renew
```

Show DNS servers:
```cmd
nslookup
```

### Network Configuration
Show network adapters:
```powershell
Get-NetAdapter | Where-Object Status -eq Up | Format-Table -AutoSize
```

Show IP configuration:
```powershell
Get-NetIPAddress | Where-Object AddressState -eq Preferred | Format-Table ifIndex, IPAddress, AddressFamily, PrefixLength -AutoSize
```

Show routing table:
```cmd
route print
```

### Port and Connection Monitoring
Listening TCP ports:
```powershell
Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Format-Table -AutoSize
```

Find process by port:
```cmd
netstat -ano | findstr ":8080"
```
Then get process details:
```powershell
Get-Process -Id <PID>
```

All network connections:
```cmd
netstat -an
```

### Firewall Management
Show firewall status:
```cmd
netsh advfirewall show allprofiles
```

List firewall rules:
```powershell
Get-NetFirewallRule | Where-Object Enabled -eq True | Select-Object DisplayName, Direction, Action | Format-Table -AutoSize
```

---

## Storage & Disk Management

### Disk Space Information
Deprecated (still works on some systems):
```cmd
wmic logicaldisk get name,freespace,size
```

Modern PowerShell:
```powershell
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{n='Free(GB)';e={[math]::Round($_.FreeSpace/1GB,2)}}, @{n='Size(GB)';e={[math]::Round($_.Size/1GB,2)}}, @{n='%Free';e={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}} | Format-Table -AutoSize
```

### Disk Health
Check disk health:
```cmd
chkdsk C: /f /r
```

SMART status:
```cmd
wmic diskdrive get status
```

### File and Folder Operations
Largest folders in current directory:
```powershell
Get-ChildItem -Directory | ForEach-Object {
  [pscustomobject]@{
    Name = $_.FullName
    SizeGB = [math]::Round((Get-ChildItem $_ -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1GB, 2)
  }
} | Sort-Object SizeGB -Descending | Select-Object -First 20 | Format-Table -AutoSize
```

Find large files (top 50):
```powershell
Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
  Sort-Object Length -Descending |
  Select-Object -First 50 FullName, @{n='SizeMB';e={[math]::Round($_.Length/1MB,2)}} |
  Format-Table -AutoSize
```

Compress a folder:
```powershell
Compress-Archive -Path "C:\Path\To\Folder" -DestinationPath "C:\Path\To\folder.zip" -Force
```

Get file hash:
```powershell
Get-FileHash "C:\Path\To\File.ext" -Algorithm SHA256
```

Find duplicate files by hash:
```powershell
Get-ChildItem -Recurse -File | Group-Object { (Get-FileHash $_.FullName).Hash } | Where-Object Count -gt 1 | ForEach-Object { $_.Group | Select-Object FullName, Length }
```

### Disk Cleanup
Clean temp files:
```cmd
del /q/f/s %TEMP%\*
```

Empty recycle bin:
```powershell
Clear-RecycleBin -Force
```

---

## Process & Performance Management

### Process Monitoring
Top CPU processes:
```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, PM | Format-Table -AutoSize
```

Memory-heavy processes:
```powershell
Get-Process | Sort-Object PM -Descending | Select-Object -First 10 Name, Id, PM | Format-Table -AutoSize
```

Real-time process monitoring (create monitoring script):
```powershell
# Save as: monitor_processes.ps1
while ($true) {
    Clear-Host
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, PM | Format-Table -AutoSize
    Start-Sleep -Seconds 2
}
```

### System Performance
Quick GPU info:
```powershell
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, DriverDate | Format-Table -AutoSize
```

Memory usage:
```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object @{n='TotalMemoryGB';e={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}}, @{n='FreeMemoryGB';e={[math]::Round($_.FreePhysicalMemory/1MB,2)}} | Format-List
```

Performance counters:
```powershell
Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5
```

---

## Weather & External APIs

Simple weather:
```powershell
Invoke-RestMethod 'https://wttr.in?format=3'
```

Detailed weather:
```powershell
Invoke-RestMethod 'https://wttr.in?format=4'
```

Weather for specific city:
```powershell
Invoke-RestMethod 'https://wttr.in/London?format=3'
```

---

## Fun & Utility Scripts

### Typing Effect (fixed+improved)
```powershell
# Save as: type_effect.ps1
function Type-Out {
  param(
    [Parameter(Mandatory)][string]$Text,
    [int]$DelayMs = 50,
    [ConsoleColor]$Color = 'White'
  )
  $Text.ToCharArray() | ForEach-Object {
    Write-Host -NoNewline $_ -ForegroundColor $Color
    Start-Sleep -Milliseconds $DelayMs
  }
  Write-Host
}

Type-Out -Text "Hello, Bismaya!" -DelayMs 100 -Color Green
```

### System Information Display Script
```powershell
# Save as: system_summary.ps1
function Show-SystemSummary {
    $computerInfo = Get-ComputerInfo
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    Write-Host "=== SYSTEM SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Computer: $($computerInfo.CsName)" -ForegroundColor Yellow
    Write-Host "OS: $($computerInfo.WindowsProductName)" -ForegroundColor Yellow
    Write-Host "Version: $($computerInfo.WindowsVersion)" -ForegroundColor Yellow
    Write-Host "Uptime: $((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime)" -ForegroundColor Yellow
    Write-Host "C: Drive: $([math]::Round($disk.FreeSpace/1GB,2))GB free of $([math]::Round($disk.Size/1GB,2))GB" -ForegroundColor Yellow
    Write-Host "=====================" -ForegroundColor Cyan
}

Show-SystemSummary
```

---

## Wi‑Fi Management (Run as Administrator)

### Wi‑Fi Profiles and Keys (fixed, safer)
**Note:** Displays saved Wi‑Fi passwords. Keep output private.

```powershell
# Save as: wifi_passwords.ps1 (Run as Administrator)
$profiles = netsh wlan show profiles |
  Select-String "All User Profile" |
  ForEach-Object { ($_ -split ":",2)[1].Trim() }

$result = foreach ($name in $profiles) {
  $detail = netsh wlan show profile name="$name" key=clear
  $keyLine = $detail | Select-String "Key Content"
  $pass = if ($keyLine) { ($keyLine -split ":",2)[1].Trim() } else { "<no password / not available>" }
  [pscustomobject]@{ SSID = $name; Password = $pass }
}

$result | Format-Table -AutoSize
```

### Wi-Fi Network Management
Show available networks:
```cmd
netsh wlan show profiles
```

Connect to network:
```cmd
netsh wlan connect name="NetworkName"
```

Disconnect from network:
```cmd
netsh wlan disconnect
```

---

## System Maintenance & Updates

### Windows Updates
Update apps with WinGet:
```cmd
winget upgrade --all --silent
```

List available updates:
```cmd
winget upgrade
```

Check Windows Update status:
```powershell
Get-WindowsUpdate
```

### Startup Management
List startup commands:
```powershell
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -Wrap
```

Manage startup programs:
```cmd
msconfig
```

### System File Integrity
System file checker:
```cmd
sfc /scannow
```

DISM health check:
```cmd
dism /online /cleanup-image /checkhealth
```

### Registry and System Cleanup
Clean registry (use with caution):
```cmd
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
```

### Service Management
List running services:
```powershell
Get-Service | Where-Object Status -eq Running | Format-Table -AutoSize
```

Stop/Start service:
```powershell
Stop-Service -Name "ServiceName"
Start-Service -Name "ServiceName"
```

---

## File Operations & Utilities

### Quick File Operations
Open current folder in Explorer:
```powershell
ii .
```

Open command prompt in current location:
```cmd
cmd
```

### File Search and Management
Find files by name:
```cmd
dir /s "filename.*"
```

PowerShell file search:
```powershell
Get-ChildItem -Recurse -Name "*filename*"
```

Find files modified in last 7 days:
```powershell
Get-ChildItem -Recurse -File | Where-Object LastWriteTime -gt (Get-Date).AddDays(-7) | Select-Object FullName, LastWriteTime | Format-Table -AutoSize
```

### Batch File Operations
Create a backup script:
```batch
@echo off
REM Save as: backup.bat
set source=C:\Important\Files
set destination=D:\Backup\%date:~-4,4%-%date:~-10,2%-%date:~-7,2%
xcopy "%source%" "%destination%" /E /I /Y
echo Backup completed to %destination%
pause
```

---

## Environment & Terminal Customization

### Environment Variables
Show PATH neatly:
```powershell
$env:Path -split ';' | Where-Object { $_ } | Sort-Object
```

Add to PATH temporarily:
```powershell
$env:Path += ";C:\NewPath"
```

Show all environment variables:
```cmd
set
```

### Terminal & PowerShell Customization
Start Windows Terminal in current directory (if installed):
```cmd
wt .
```

Open PowerShell profile for customization:
```powershell
notepad $PROFILE
```

Create profile if missing:
```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
```

Sample PowerShell profile content:
```powershell
# Save in: $PROFILE
# Custom prompt
function prompt {
    $currentPath = (Get-Location).Path.Replace($HOME, "~")
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host (Get-Date -Format "HH:mm:ss") -NoNewline -ForegroundColor Green
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host $currentPath -ForegroundColor Blue
    return "PS> "
}

# Useful aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String
Set-Alias -Name which -Value Get-Command
```

---

## Advanced System Tools

### Task Scheduler
List scheduled tasks:
```powershell
Get-ScheduledTask | Where-Object State -eq Ready | Format-Table -AutoSize
```

### Windows Features
List Windows features:
```powershell
Get-WindowsOptionalFeature -Online | Where-Object State -eq Enabled | Format-Table -AutoSize
```

Enable Windows feature:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux"
```

### Registry Operations (Use with caution)
Query registry:
```cmd
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
```

### Event Viewer Shortcuts
Open Event Viewer:
```cmd
eventvwr.msc
```

Device Manager:
```cmd
devmgmt.msc
```

Services:
```cmd
services.msc
```

System Configuration:
```cmd
msconfig
```

---

## Emergency & Recovery

### System Restore
Create restore point:
```powershell
Checkpoint-Computer -Description "Manual checkpoint"
```

### Safe Mode Boot
Boot to safe mode:
```cmd
bcdedit /set {default} safeboot minimal
```

Normal boot (after safe mode):
```cmd
bcdedit /deletevalue {default} safeboot
```

### Emergency System Reset
Reset network settings:
```cmd
netsh winsock reset
netsh int ip reset
```

Restart Explorer (if frozen):
```powershell
Stop-Process -Name explorer -Force; Start-Process explorer.exe
```

---

**Remember:** Always backup important data before running system-modifying commands. Test scripts in a safe environment first.