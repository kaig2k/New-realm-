@echo off
setlocal
rem Compile src\ into bin\NewRealm.swf using the AIR SDK's amxmlc (needs Java).
cd /d "%~dp0"
call "%~dp0findsdk.bat"
if errorlevel 1 goto fail
if not exist bin mkdir bin
rem Optional: build.bat your.server.com:2050 bakes your server into the game,
rem so players who open the .swf join it automatically.
if not "%~1"=="" call :setserver "%~1"
call "%AIR_SDK%\bin\amxmlc" -source-path=src -output=bin\NewRealm.swf src\NewRealm.as || goto fail
echo Built bin\NewRealm.swf
if not "%~1"=="" call "%AIR_SDK%\bin\amxmlc" -source-path=src -output=bin\EldmereLauncher.swf src\Launcher.as || goto fail
if not "%~1"=="" echo Players who open it join %~1 automatically.
if not "%~1"=="" echo Built bin\EldmereLauncher.swf: give this to players once; it always loads the latest game from %~1.
exit /b 0

:setserver
> src\realm\ServerConfig.as (
	echo package realm {
	echo 	/** Your server, baked into the game by build.bat. Empty = offline-first build. */
	echo 	public class ServerConfig {
	echo 		public static const HOME:String = "%~1";
	echo 		/** The server the Eldmere launcher started this game for. */
	echo 		public static var launched:String = "";
	echo 		public static function get home^(^):String { return HOME ^|^| launched; }
	echo 	}
	echo }
)
exit /b 0

:fail
echo.
pause
exit /b 1
