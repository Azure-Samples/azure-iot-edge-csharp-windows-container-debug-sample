
@echo off
SETLOCAL EnableDelayedExpansion

set LOCAL_BIN_STAGING_DIR=BinariesToCopy
set VS_REMOTE_DEBUGGER_BIN="%VSINSTALLDIR%CoreCon\Binaries\Phone Tools\Debugger\target\x64"
set VS_REMOTE_DEBUGGER_LIB="%VSINSTALLDIR%CoreCon\Binaries\Phone Tools\Debugger\target\lib"

set VS_DOTNET_CORE_CLR="%VSINSTALLDIR%CoreCon\Binaries\Phone Tools\Debugger\CoreClr\x64"

set VS_OUT_DIR="c:/app"
set DockerImageName=iotedgemodule1:0.0.1-windows-amd64.debug

:: Check execution environment
if "%VSINSTALLDIR%" == "" (
    goto RunFromDevCmd
)

::Check for VS 2017 + Pre-reqs
if not exist %VS_REMOTE_DEBUGGER_BIN% (
    goto NoVs
) 

::Check for docker
call docker.exe version >nul
if ERRORLEVEL 1 (
    goto NoDocker
)

call robocopy.exe !VS_DOTNET_CORE_CLR! %LOCAL_BIN_STAGING_DIR% /S /E >null
if %ERRORLEVEL% GTR 8 (
    echo Error while staging CLR binaries. Exiting...
    exit /b 1
)

:: Copy to local staging directory
echo Staging Remote Binaries.
call robocopy.exe %VS_REMOTE_DEBUGGER_BIN% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries. Exiting...
    exit /b 1
)

call robocopy.exe %VS_REMOTE_DEBUGGER_LIB% %LOCAL_BIN_STAGING_DIR% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    echo Error while staging debugger binaries. Exiting...
    exit /b 1
)

echo Building container...
docker build -t %DockerImageName% --build-arg VS_REMOTE_DEBUGGER_PATH=%LOCAL_BIN_STAGING_DIR% --build-arg VS_OUT_DIR=%VS_OUT_DIR%  -f Dockerfile.windows-amd64.debug . 

# you can push image to docker hub use the commands below:
# docker tag %DockerImageName% yourRepoName/%DockerImageName%
# docker push yourRepoName/%DockerImageName%

echo Stop module in container...
iotedgehubdev stop


echo Start edge module in container...
iotedgehubdev start -d "..\AzureIotEdgeApp1.Windows.Amd64\config\deployment.windows-amd64.debug.json"

if ERRORLEVEL 1 (
    echo Encountered error while building Container, exiting..
    goto :EOF
)

:: cleanup staged files
if exist %LOCAL_BIN_STAGING_DIR% (
:: rd /Q /S %LOCAL_BIN_STAGING_DIR%
)

goto :EOF

:InvalidDeployPath
echo.
echo   Incorrect test binaries path 
echo.
goto :EOF

:RunFromDevCmd
echo.
echo  Please run the script in a Visual Studio Developer Command Prompt 
echo.
goto :EOF

:NoVs
echo.
echo Pre-requisites missing:
echo.
echo    Visual Studio 2017 with following workloads:
echo        Universal Windows Platform Development
echo        Desktop Development with C++
echo.
echo    Free Commmunity Edition available from visualstudio.com
echo.
goto :EOF

:NoDocker
echo.
echo Pre-requisites missing:
echo.
echo    Docker for Windows missing or not in PATH
echo.
echo    Free download available at: https://docs.docker.com/docker-for-windows/
echo.
goto :EOF

:Usage
echo.
echo Usage:
echo.
echo    BuildAndRun.cmd
echo.
goto :EOF