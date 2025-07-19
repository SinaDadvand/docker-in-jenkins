@echo off
REM Comprehensive Windows build script for Jenkins Docker Demo

setlocal enabledelayedexpansion

REM Configuration
set IMAGE_NAME=jenkins-docker-demo
set VERSION=%APP_VERSION%
if "%VERSION%"=="" set VERSION=1.0.0
set BUILD_NUMBER=%BUILD_NUMBER%
if "%BUILD_NUMBER%"=="" (
    for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set BUILD_NUMBER=%%c%%a%%b
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set BUILD_NUMBER=!BUILD_NUMBER!-%%a%%b
)
set REGISTRY=%DOCKER_REGISTRY%
if "%REGISTRY%"=="" set REGISTRY=localhost:5000

echo [INFO] Starting Docker build process...
echo [INFO] Image: %IMAGE_NAME%
echo [INFO] Version: %VERSION%
echo [INFO] Build Number: %BUILD_NUMBER%

REM Step 1: Validate Docker is running
echo [INFO] Checking Docker availability...
docker info >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Docker is not running or not accessible
    exit /b 1
)
echo [SUCCESS] Docker is available

REM Step 2: Clean up previous builds
echo [INFO] Cleaning up old images...
docker image prune -f --filter "label=description=Jenkins Docker Demo*" 2>nul

REM Step 3: Build production image
echo [INFO] Building production Docker image...
docker build ^
    --file Dockerfile ^
    --tag %IMAGE_NAME%:%VERSION% ^
    --tag %IMAGE_NAME%:%BUILD_NUMBER% ^
    --tag %IMAGE_NAME%:latest ^
    --build-arg NODE_ENV=production ^
    --build-arg APP_VERSION=%VERSION% ^
    --build-arg BUILD_NUMBER=%BUILD_NUMBER% ^
    --label "build.number=%BUILD_NUMBER%" ^
    .

if !errorlevel! equ 0 (
    echo [SUCCESS] Production image built successfully
) else (
    echo [ERROR] Failed to build production image
    exit /b 1
)

REM Step 4: Build development image
echo [INFO] Building development Docker image...
docker build ^
    --file docker\Dockerfile.dev ^
    --tag %IMAGE_NAME%:dev ^
    --build-arg NODE_ENV=development ^
    .

if !errorlevel! equ 0 (
    echo [SUCCESS] Development image built successfully
) else (
    echo [WARNING] Failed to build development image (non-critical)
)

REM Step 5: Test the built image
echo [INFO] Testing built image...
for /f %%i in ('docker run -d -p 3001:3000 %IMAGE_NAME%:%VERSION%') do set CONTAINER_ID=%%i

if !errorlevel! equ 0 (
    echo [INFO] Container started with ID: !CONTAINER_ID!
    
    REM Wait for application to start
    timeout /t 5 /nobreak >nul
    
    REM Test health endpoint using PowerShell
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:3001/health' -UseBasicParsing -TimeoutSec 5 | Out-Null; exit 0 } catch { exit 1 }"
    if !errorlevel! equ 0 (
        echo [SUCCESS] Health check passed
    ) else (
        echo [ERROR] Health check failed
        docker logs !CONTAINER_ID!
        docker stop !CONTAINER_ID!
        docker rm !CONTAINER_ID!
        exit /b 1
    )
    
    REM Cleanup test container
    docker stop !CONTAINER_ID!
    docker rm !CONTAINER_ID!
    echo [SUCCESS] Test container cleaned up
) else (
    echo [ERROR] Failed to start test container
    exit /b 1
)

REM Step 6: Display build results
echo [SUCCESS] Build completed successfully!
echo [INFO] Generated images:
docker images | findstr %IMAGE_NAME%

REM Step 7: Create build metadata
(
echo {
echo   "image_name": "%IMAGE_NAME%",
echo   "version": "%VERSION%",
echo   "build_number": "%BUILD_NUMBER%",
echo   "build_timestamp": "%date% %time%",
echo   "tags": [
echo     "%IMAGE_NAME%:%VERSION%",
echo     "%IMAGE_NAME%:%BUILD_NUMBER%",
echo     "%IMAGE_NAME%:latest"
echo   ]
echo }
) > build-metadata.json

echo [SUCCESS] Build metadata saved to build-metadata.json
echo [SUCCESS] Docker build process completed successfully!

endlocal