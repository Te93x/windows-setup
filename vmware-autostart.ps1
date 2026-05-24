# ================================================
# VMware Auto Start Setup - One-Liner Friendly
# Usage: Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command irm https://raw.githubusercontent.com/Te93x/YOUR-REPO/main/vmware-autostart.ps1 | iex"
# ================================================

param(
    [string]$TaskName = "Start-VMware-VM",
    [string]$BatchFilePath = "$env:USERPROFILE\StartVM.bat",
    [int]$DelaySeconds = 45
)

# Auto elevate to Administrator if not already
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "VMware Auto Start Setup" -ForegroundColor Cyan

# File Picker
Write-Host "Please select your .vmx file..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Windows.Forms
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.Title = "Select VMware Virtual Machine (.vmx)"
$openFileDialog.Filter = "VMware VM Files (*.vmx)|*.vmx"
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")

if ($openFileDialog.ShowDialog() -ne "OK") {
    Write-Host "No file selected. Setup cancelled." -ForegroundColor Red
    exit 1
}

$VMXPath = $openFileDialog.FileName
Write-Host "Selected: $VMXPath" -ForegroundColor Green

# Create Batch File
$batchContent = @"
@echo off
echo [%date% %time%] Waiting $DelaySeconds seconds... >> "%~dp0VM-Start.log"
timeout /t $DelaySeconds /nobreak >nul
echo [%date% %time%] Starting VM: $VMXPath >> "%~dp0VM-Start.log"
"C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" start "$VMXPath" nogui
if %errorlevel% equ 0 (echo [%date% %time%] Success >> "%~dp0VM-Start.log") else (echo [%date% %time%] Failed >> "%~dp0VM-Start.log")
"@

$batchContent | Out-File -FilePath $BatchFilePath -Encoding ASCII -Force

# Create Task
$action = New-ScheduledTaskAction -Execute $BatchFilePath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 15) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "✅ Successfully created auto-start task with 45s delay!" -ForegroundColor Green
Write-Host "Log file will be at: $env:USERPROFILE\VM-Start.log" -ForegroundColor Cyan