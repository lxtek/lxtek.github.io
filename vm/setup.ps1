#Requires -RunAsAdministrator

<#
.SYNOPSIS
   Авто установка хуйни
.DESCRIPTION
    Авто установка некоторых программ в cmd для VM [Обычные пк тоже ворк, но хз]
.NOTES
 Требует АДМ
 #>

function Show-Logo {
    Clear-Host
    $logo = @"
  ==================================================================
  
       WIN   WIN III NN   NN    VV     VV MM    MM
       WIN   WIN III NNN  NN    VV     VV MMM  MMM
       WIN W WIN III NN N NN     VV   VV  MM MM MM
       WIN W WIN III NN  NNN      VV VV   MM    MM
        WW   WW  III NN   NN       VVV    MM    MM
  
              Windows VM Setup Script v2.1
                  by chatgpthvh.t.me
  
  ==================================================================
"@
    
    foreach ($line in $logo -split "`n") {
        Write-Host $line -ForegroundColor Cyan
        Start-Sleep -Milliseconds 30
    }
    Write-Host ""
}

Show-Logo

Write-Host "  ==================================================================" -ForegroundColor Magenta
Write-Host "    SELECT WALLPAPER" -ForegroundColor Magenta
Write-Host "  ==================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "    1. Blue Nord Theme" -ForegroundColor Cyan
Write-Host "    2. Gray Nord Theme" -ForegroundColor Gray
Write-Host ""
Write-Host "  Enter your choice (1 or 2): " -NoNewline -ForegroundColor Yellow
$wallpaperChoice = Read-Host

$wallpaperFile = switch ($wallpaperChoice) {
    "1" { "BLUENord.jpg" }
    "2" { "GRAYNord.jpg" }
    default { 
        Write-Host "  Invalid choice, defaulting to Blue Nord" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        "BLUENord.jpg" 
    }
}

Write-Host ""
Write-Host "  Selected: $wallpaperFile" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1

$setupFolder = "C:\SandboxSetup"
$logsFolder = Join-Path $setupFolder "Logs"
$logFile = Join-Path $logsFolder "setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

$downloads = @(
    @{
        Url = "https://lxtek.github.io/vm/7z2409-x64.exe"
        FileName = "7z2409-x64.exe"
        Description = "7-Zip Archive Manager"
        Type = "Installer"
    },
    @{
        Url = "https://lxtek.github.io/vm/BraveBrowserSetup-BRV013.exe"
        FileName = "BraveBrowserSetup-BRV013.exe"
        Description = "Brave Browser"
        Type = "Installer"
    },
    @{
        Url = "https://lxtek.github.io/vm/Everything-1.4.1.1030.x86-Setup.exe"
        FileName = "Everything-1.4.1.1030.x86-Setup.exe"
        Description = "Everything Search"
        Type = "Installer"
    },
    @{
        Url = "https://crystalidea.com/downloads/uninstalltool_setup.exe"
        FileName = "uninstalltool_setup.exe"
        Description = "Uninstall Tool"
        Type = "Installer"
    },
    @{
        Url = "https://www.softportal.com/en/process-hacker/2/getsoft"
        FileName = "processhacker-2.39-setup.exe"
        Description = "Process Hacker"
        Type = "Installer"
    },
    @{
        Url = "https://www.sublimetext.com/download_thanks?target=win-x64"
        FileName = "sublime_text_build_4200_x64_setup.exe"
        Description = "Sublime Text"
        Type = "Installer"
    },

    @{
        Url = "https://lxtek.github.io/vm/Procmon64.exe"
        FileName = "Procmon64.exe"
        Description = "Process Monitor (Sysinternals)"
        Type = "Portable"
    },
    @{
        Url = "https://lxtek.github.io/vm/Autoruns64.exe"
        FileName = "Autoruns64.exe"
        Description = "Autoruns (Sysinternals)"
        Type = "Portable"
    },
    @{
        Url = "https://lxtek.github.io/vm/$wallpaperFile"
        FileName = $wallpaperFile
        Description = "Desktop Wallpaper"
        Type = "Resource"
    }
)

$script:stats = @{
    Downloaded = 0
    Skipped = 0
    Installed = 0
    Failed = 0
    StartTime = Get-Date
}

function Write-Log {
    param([string]$Message)
    try {
        if (Test-Path $logsFolder) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    } catch {
    }
}

function Write-Progress-Message {
    param(
        [string]$Type,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output = ""
    
    switch ($Type) {
        "Info"    { 
            $output = "[$timestamp] [+] $Message"
            Write-Host $output -ForegroundColor Cyan 
        }
        "Success" { 
            $output = "[$timestamp] [OK] $Message"
            Write-Host $output -ForegroundColor Green 
        }
        "Skip"    { 
            $output = "[$timestamp] [~] $Message"
            Write-Host $output -ForegroundColor Yellow 
        }
        "Error"   { 
            $output = "[$timestamp] [!] $Message"
            Write-Host $output -ForegroundColor Red 
        }
        "Header"  { 
            Write-Host ""
            Write-Host "  ==================================================================" -ForegroundColor Magenta
            Write-Host "    $Message" -ForegroundColor Magenta
            Write-Host "  ==================================================================" -ForegroundColor Magenta
            Write-Host ""
            $output = "=== $Message ==="
        }
    }
    
    Write-Log $output
}

function Show-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 50
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "[" + ("#" * $filled) + ("." * $empty) + "]"
    Write-Host "`r  $bar $percent% - $Activity" -NoNewline -ForegroundColor Cyan
}

function Test-InternetConnection {
    Write-Progress-Message -Type "Info" -Message "Testing internet connectivity..."
    try {
        $result = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet -ErrorAction SilentlyContinue
        if ($result) {
            Write-Progress-Message -Type "Success" -Message "Internet connection verified"
            return $true
        } else {
            Write-Progress-Message -Type "Error" -Message "No internet connection detected"
            return $false
        }
    } catch {
        Write-Progress-Message -Type "Error" -Message "Could not verify internet connection"
        return $false
    }
}

function Get-SystemInfo {
    Write-Progress-Message -Type "Header" -Message "SYSTEM INFORMATION"
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    
    Write-Host "  OS:        " -NoNewline -ForegroundColor Gray
    Write-Host "$($os.Caption) ($($os.OSArchitecture))" -ForegroundColor White
    
    Write-Host "  CPU:       " -NoNewline -ForegroundColor Gray
    Write-Host "$($cpu.Name)" -ForegroundColor White
    
    Write-Host "  RAM:       " -NoNewline -ForegroundColor Gray
    Write-Host "$ram GB (Free: $freeRam GB)" -ForegroundColor White
    
    Write-Host "  User:      " -NoNewline -ForegroundColor Gray
    Write-Host "$env:USERNAME" -ForegroundColor White
    
    Write-Host "  Date:      " -NoNewline -ForegroundColor Gray
    Write-Host "$(Get-Date -Format 'dddd, MMMM dd, yyyy HH:mm:ss')" -ForegroundColor White
    
    Write-Log "System Info - OS: $($os.Caption), CPU: $($cpu.Name), RAM: $ram GB"
}

Get-SystemInfo
Start-Sleep -Seconds 2

Write-Progress-Message -Type "Header" -Message "CREATING DIRECTORIES"

try {
    if (-not (Test-Path $setupFolder)) {
        New-Item -Path $setupFolder -ItemType Directory -Force | Out-Null
        Write-Progress-Message -Type "Success" -Message "Created: $setupFolder"
    } else {
        Write-Progress-Message -Type "Skip" -Message "Already exists: $setupFolder"
    }
    
    if (-not (Test-Path $logsFolder)) {
        New-Item -Path $logsFolder -ItemType Directory -Force | Out-Null
        Write-Progress-Message -Type "Success" -Message "Created: $logsFolder"
    }
    
    Write-Log "Setup folders created successfully"
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to create directories: $_"
    Write-Log "ERROR: Directory creation failed - $_"
    exit 1
}

if (-not (Test-InternetConnection)) {
    Write-Progress-Message -Type "Error" -Message "Internet connection required for downloads"
    Read-Host "`nPress Enter to exit"
    exit 1
}

Write-Progress-Message -Type "Header" -Message "DOWNLOADING FILES"

$downloadedFiles = @()
$totalDownloads = $downloads.Count

for ($i = 0; $i -lt $totalDownloads; $i++) {
    $download = $downloads[$i]
    $filePath = Join-Path $setupFolder $download.FileName
    
    Show-ProgressBar -Current ($i + 1) -Total $totalDownloads -Activity "Downloading files"
    Write-Host ""
    
    Write-Progress-Message -Type "Info" -Message "[$($i+1)/$totalDownloads] Downloading $($download.Description)..."
    Write-Host "    Source: $($download.Url)" -ForegroundColor Gray
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        $webClient.DownloadFile($download.Url, $filePath)
        
        if (Test-Path $filePath) {
            $fileSize = (Get-Item $filePath).Length / 1MB
            Write-Progress-Message -Type "Success" -Message "Downloaded $($download.FileName) ({0:N2} MB)" -f $fileSize
            $downloadedFiles += $download
            $script:stats.Downloaded++
            Write-Log "SUCCESS: Downloaded $($download.FileName) - {0:N2} MB" -f $fileSize
        }
    } catch {
        $errorReason = "Unknown error"
        if ($_.Exception.Message -match "404") {
            $errorReason = "File not found on server (HTTP 404)"
        } elseif ($_.Exception.Message -match "403") {
            $errorReason = "Access forbidden (HTTP 403)"
        } elseif ($_.Exception.Message -match "timeout|timed out") {
            $errorReason = "Connection timeout - server not responding"
        } elseif ($_.Exception.Message -match "DNS|could not be resolved") {
            $errorReason = "DNS resolution failed - domain not reachable"
        } elseif ($_.Exception.Message -match "SSL|TLS|certificate") {
            $errorReason = "SSL/TLS certificate error"
        } elseif ($_.Exception.Message -match "Could not create SSL/TLS") {
            $errorReason = "Secure connection could not be established"
        } else {
            $errorReason = $_.Exception.Message
        }
        Write-Progress-Message -Type "Skip" -Message "Could not download $($download.FileName)"
        Write-Host "    Reason: $errorReason" -ForegroundColor DarkYellow
        $script:stats.Skipped++
        Write-Log "SKIP: $($download.FileName) - $errorReason"
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""

Write-Progress-Message -Type "Header" -Message "INSTALLING PROGRAMS"

$installers = Get-ChildItem -Path $setupFolder -Filter "*.exe" | Where-Object { $_.Name -notmatch "Procmon64|Autoruns64" }
if ($installers.Count -eq 0) {
    Write-Progress-Message -Type "Skip" -Message "No installers found to run"
    Write-Log "SKIP: No installers available"
} else {
    Write-Host "  Found $($installers.Count) installer(s) ready to run" -ForegroundColor Yellow
    Write-Host "  Please complete each installation manually when prompted" -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
    
    $installerNum = 1
    foreach ($installer in $installers) {
        Write-Progress-Message -Type "Info" -Message "[$installerNum/$($installers.Count)] Launching: $($installer.Name)"
        Write-Host "    Path: $($installer.FullName)" -ForegroundColor Gray
        Write-Host "    Waiting for installation to complete..." -ForegroundColor Yellow
        
        try {
            $process = Start-Process -FilePath $installer.FullName -PassThru -Wait
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq $null) {
                Write-Progress-Message -Type "Success" -Message "Completed: $($installer.Name)"
                $script:stats.Installed++
                Write-Log "SUCCESS: Installed $($installer.Name)"
            } else {
                Write-Progress-Message -Type "Skip" -Message "Installation cancelled or failed (Exit Code: $($process.ExitCode))"
                Write-Log "SKIP: $($installer.Name) - Exit Code: $($process.ExitCode)"
            }
        } catch {
            Write-Progress-Message -Type "Error" -Message "Failed to launch $($installer.Name): $_"
            $script:stats.Failed++
            Write-Log "ERROR: $($installer.Name) - $_"
        }
        
        $installerNum++
        Write-Host ""
    }
}

Write-Progress-Message -Type "Header" -Message "DEPLOYING PORTABLE TOOLS"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$portableTools = @("Procmon64.exe", "Autoruns64.exe")

foreach ($tool in $portableTools) {
    $sourcePath = Join-Path $setupFolder $tool
    $destPath = Join-Path $desktopPath $tool
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Progress-Message -Type "Success" -Message "Copied $tool to Desktop"
            Write-Log "SUCCESS: Copied $tool to Desktop"
        } catch {
            Write-Progress-Message -Type "Error" -Message "Failed to copy $tool to Desktop: $_"
            Write-Log "ERROR: Failed to copy $tool - $_"
        }
    } else {
        Write-Progress-Message -Type "Skip" -Message "$tool not found (may not have downloaded)"
        Write-Log "SKIP: $tool not available"
    }
}

Write-Progress-Message -Type "Header" -Message "CUSTOMIZING APPEARANCE"

$wallpaperPath = Join-Path $setupFolder $wallpaperFile
if (Test-Path $wallpaperPath) {
    Write-Progress-Message -Type "Info" -Message "Applying desktop wallpaper..."
    
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $wallpaperPath
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value 2  # Stretch
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 0
        
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $wallpaperPath, 0x0003)
        
        Write-Progress-Message -Type "Success" -Message "Wallpaper applied successfully"
        Write-Log "SUCCESS: Wallpaper set to $wallpaperPath"
    } catch {
        Write-Progress-Message -Type "Error" -Message "Failed to set wallpaper: $_"
        Write-Log "ERROR: Wallpaper - $_"
    }
} else {
    Write-Progress-Message -Type "Skip" -Message "Wallpaper file not found"
    Write-Log "SKIP: Wallpaper file not available"
}

Write-Progress-Message -Type "Info" -Message "Enabling dark theme..."

try {
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value 0 -Type DWord
    
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value 0 -Type DWord
        
    Write-Progress-Message -Type "Success" -Message "Dark theme enabled"
    Write-Log "SUCCESS: Dark theme applied"
    
    Write-Progress-Message -Type "Info" -Message "Restarting Explorer to apply changes..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    Write-Progress-Message -Type "Success" -Message "Explorer restarted"
    Write-Log "SUCCESS: Explorer restarted"
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to apply dark theme: $_"
    Write-Log "ERROR: Dark theme - $_"
}

Write-Progress-Message -Type "Header" -Message "KEYBOARD CONFIGURATION"

try {
    Write-Progress-Message -Type "Info" -Message "Adding English (US) and Russian keyboard layouts..."
    
    $langList = New-WinUserLanguageList -Language "en-US"
    $langList.Add("ru-RU")
    Set-WinUserLanguageList -LanguageList $langList -Force
    
    New-Item -Path "HKCU:\Keyboard Layout\Toggle" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Toggle" -Name "Hotkey" -Value "1" -Type String
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Toggle" -Name "Language Hotkey" -Value "1" -Type String
    Set-ItemProperty -Path "HKCU:\Keyboard Layout\Toggle" -Name "Layout Hotkey" -Value "2" -Type String
    
    Write-Progress-Message -Type "Success" -Message "Keyboard layouts configured"
    Write-Host "    - English (US) - Primary" -ForegroundColor Gray
    Write-Host "    - Russian (RU) - Secondary" -ForegroundColor Gray
    Write-Host "    - Switch: Alt + Shift" -ForegroundColor Cyan
    Write-Log "SUCCESS: Keyboard layouts EN-US, RU-RU configured with Alt+Shift"
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to configure keyboard layouts: $_"
    Write-Log "ERROR: Keyboard configuration - $_"
}

Write-Progress-Message -Type "Header" -Message "PERFORMANCE OPTIMIZATION"

try {
    Write-Progress-Message -Type "Info" -Message "Setting High Performance power plan..."
    $powerPlanOutput = powercfg /list
    $highPerfLine = $powerPlanOutput | Where-Object { $_ -match "High performance" }
    
    if ($highPerfLine) {
        $guid = [regex]::Match($highPerfLine, '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}').Value
        if ($guid) {
            powercfg /setactive $guid 2>$null
            Write-Progress-Message -Type "Success" -Message "High Performance plan activated"
            Write-Log "SUCCESS: High Performance power plan activated"
        } else {
            Write-Progress-Message -Type "Skip" -Message "Could not parse power plan GUID"
            Write-Log "SKIP: Power plan GUID parsing failed"
        }
    } else {
        Write-Progress-Message -Type "Skip" -Message "High Performance plan not available"
        Write-Log "SKIP: High Performance power plan not found"
    }
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to set power plan: $_"
    Write-Log "ERROR: Power plan - $_"
}

try {
    Write-Progress-Message -Type "Info" -Message "Disabling hibernation..."
    powercfg /hibernate off 2>$null
    Write-Progress-Message -Type "Success" -Message "Hibernation disabled"
    Write-Log "SUCCESS: Hibernation disabled"
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to disable hibernation: $_"
    Write-Log "ERROR: Hibernation - $_"
}

try {
    Write-Progress-Message -Type "Info" -Message "Stopping Windows Search service..."
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Set-Service -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Progress-Message -Type "Success" -Message "Windows Search disabled"
    Write-Log "SUCCESS: Windows Search service disabled"
} catch {
    Write-Progress-Message -Type "Error" -Message "Failed to disable Windows Search: $_"
    Write-Log "ERROR: Windows Search - $_"
}

try {
    Write-Progress-Message -Type "Info" -Message "Disabling Superfetch/SysMain..."
    Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
    Set-Service -Name SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Progress-Message -Type "Success" -Message "Superfetch/SysMain disabled"
    Write-Log "SUCCESS: Superfetch disabled"
} catch {
    Write-Progress-Message -Type "Skip" -Message "Superfetch/SysMain service not available"
    Write-Log "SKIP: Superfetch service"
}

try {
    Write-Progress-Message -Type "Info" -Message "Configuring Windows Defender for Sandbox..."
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Write-Progress-Message -Type "Success" -Message "Real-time protection disabled"
    Write-Log "SUCCESS: Windows Defender real-time protection disabled"
} catch {
    Write-Progress-Message -Type "Skip" -Message "Windows Defender configuration skipped"
    Write-Log "SKIP: Windows Defender configuration"
}

try {
    Write-Progress-Message -Type "Info" -Message "Optimizing visual performance..."
    
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name MinAnimate -Value 0
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
    
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2
    
    Write-Progress-Message -Type "Success" -Message "Visual performance optimized"
    Write-Log "SUCCESS: Visual performance optimized"
} catch {
    Write-Progress-Message -Type "Skip" -Message "Some visual tweaks may not have applied"
    Write-Log "SKIP: Visual performance tweaks partially applied"
}

$script:stats.EndTime = Get-Date
$duration = $script:stats.EndTime - $script:stats.StartTime
$durationFormatted = "{0:mm}m {0:ss}s" -f $duration

Write-Progress-Message -Type "Header" -Message "SETUP SUMMARY"

Write-Host ""
Write-Host "  ==================================================================" -ForegroundColor Cyan
Write-Host "    STATISTICS" -ForegroundColor Cyan
Write-Host "  ==================================================================" -ForegroundColor Cyan
Write-Host "    Downloads:    $($script:stats.Downloaded) successful / $($script:stats.Skipped) skipped" -ForegroundColor Cyan
Write-Host "    Installed:    $($script:stats.Installed) program(s)" -ForegroundColor Cyan
Write-Host "    Duration:     $durationFormatted" -ForegroundColor Cyan
Write-Host "  ==================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "=== SETUP COMPLETED ==="
Write-Log "Statistics: Downloads=$($script:stats.Downloaded), Skipped=$($script:stats.Skipped), Installed=$($script:stats.Installed), Duration=$durationFormatted"

# Final Message
Write-Host ""
Write-Host "  ==================================================================" -ForegroundColor Green
Write-Host "                       Setup Complete!" -ForegroundColor Green
Write-Host "  ==================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "    Installed programs in: C:\SandboxSetup" -ForegroundColor White
Write-Host "    Portable tools on Desktop: Procmon64.exe, Autoruns64.exe" -ForegroundColor White
Write-Host "    Use Alt+Shift to toggle between RU and EN" -ForegroundColor White
Write-Host "    Dark theme enabled system-wide" -ForegroundColor White
Write-Host "    Performance optimizations applied" -ForegroundColor White
Write-Host "    Logs saved to: Logs\setup_*.log" -ForegroundColor White
Write-Host ""
Write-Host "    TIP: Restart Sandbox to finalize all changes" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ==================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "  Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
