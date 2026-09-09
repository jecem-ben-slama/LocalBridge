@echo off
setlocal

set "EXE=%~dp0localbridge.exe"
set "URL=http://localhost:8080"

if not exist "%EXE%" (
    echo ERROR: localbridge.exe was not found next to this launcher.
    echo Expected file: %EXE%
    echo Put the generated executable in the same folder as this script and try again.
    pause
    exit /b 1
)

start "" "%EXE%" --server.port=8080

for /L %%I in (1,1,120) do (
    powershell -NoProfile -Command "$c = Test-NetConnection -ComputerName localhost -Port 8080 -WarningAction SilentlyContinue; if ($c.TcpTestSucceeded) { exit 0 } else { exit 1 }" >nul 2>&1
    if not errorlevel 1 goto ready
    ping -n 2 127.0.0.1 >nul
)

:ready
start "" "%URL%"
exit /b 0
