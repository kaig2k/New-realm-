@echo off
rem Packages the Eldmere desktop client (the launcher, with its own AIR runtime) into dist\Eldmere,
rem and zips it to dist\Eldmere.zip to hand to players. Build the launcher first, with your server:
rem     build.bat your.server.com:2050
rem The client downloads the latest game from that server every time it starts, so players never
rem need a new copy after an update.
setlocal
cd /d "%~dp0"
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail
if not exist bin\EldmereLauncher.swf (
	echo bin\EldmereLauncher.swf is missing. Build it first with your server's address:
	echo     build.bat your.server.com:2050
	goto fail
)
if not exist cert.p12 call "%AIR_SDK%\bin\adt" -certificate -cn Eldmere 2048-RSA cert.p12 newrealm
if not exist dist mkdir dist
rem adt won't overwrite an old bundle
if exist dist\Eldmere rmdir /s /q dist\Eldmere
call "%AIR_SDK%\bin\adt" -package -storetype pkcs12 -keystore cert.p12 -storepass newrealm -target bundle dist\Eldmere Eldmere-app.xml -C bin EldmereLauncher.swf -C assets\icons eldmere_16.png eldmere_32.png eldmere_48.png eldmere_128.png || goto fail
echo Packaged into dist\Eldmere  (players run dist\Eldmere\Eldmere.exe)
if exist dist\Eldmere.zip del dist\Eldmere.zip
powershell -NoProfile -Command "Compress-Archive -Path 'dist\Eldmere' -DestinationPath 'dist\Eldmere.zip'" && echo Zipped into dist\Eldmere.zip - give this to your players.
pause
exit /b 0

:fail
echo.
pause
exit /b 1
