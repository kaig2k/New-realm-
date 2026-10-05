@echo off
rem Starts the New Realm multiplayer server (needs Node.js from https://nodejs.org).
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is not installed. Download the LTS version from https://nodejs.org, install it, then run this again.
  pause
  exit /b 1
)
node "%~dp0server\server.js" %*
pause
