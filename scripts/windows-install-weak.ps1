# Installation script for weak PC setup (Windows 11)
# llama.cpp with TurboQuant + OpenVINO NPU support

# Requires Administrator privileges
#Requires -RunAsAdministrator

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "AI-unclove Weak PC Setup Installation" -ForegroundColor Cyan
Write-Host "llama.cpp + TurboQuant + OpenVINO NPU" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running in WSL2 is preferred
Write-Host "[INFO] This script can install either:" -ForegroundColor Yellow
Write-Host "  1. Native Windows build (requires Visual Studio)" -ForegroundColor Yellow
Write-Host "  2. WSL2 + Linux build (recommended)" -ForegroundColor Yellow
Write-Host ""
$choice = Read-Host "Choose installation type (1 or 2)"

if ($choice -eq "2") {
    Write-Host ""
    Write-Host "[1/4] Checking WSL2 installation..." -ForegroundColor Green

    if (!(wsl --list --verbose)) {
        Write-Host "Installing WSL2..." -ForegroundColor Yellow
        wsl --install -d Ubuntu-22.04
        Write-Host "WSL2 installed. Please restart and run this script again." -ForegroundColor Yellow
        exit
    }

    Write-Host ""
    Write-Host "[2/4] Installing Docker Desktop..." -ForegroundColor Green
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        Write-Host "Then run this script again." -ForegroundColor Yellow
        exit
    }

    Write-Host ""
    Write-Host "[3/4] Copying files to WSL2..." -ForegroundColor Green
    $repoPath = Get-Location
    wsl -d Ubuntu-22.04 -- bash -c "mkdir -p ~/ai-unclove"
    wsl -d Ubuntu-22.04 -- bash -c "cd ~/ai-unclove && git clone $repoPath ."

    Write-Host ""
    Write-Host "[4/4] Running Linux installation script in WSL2..." -ForegroundColor Green
    wsl -d Ubuntu-22.04 -- bash -c "cd ~/ai-unclove && sudo bash scripts/linux-install-weak.sh"

} else {
    Write-Host ""
    Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Green

    # Check Chocolatey
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    Write-Host ""
    Write-Host "[2/6] Installing build tools..." -ForegroundColor Green
    choco install -y git cmake ninja visualstudio2022buildtools visualstudio2022-workload-vctools

    Write-Host ""
    Write-Host "[3/6] Installing CUDA Toolkit..." -ForegroundColor Green
    choco install -y cuda

    Write-Host ""
    Write-Host "[4/6] Installing Intel NPU driver..." -ForegroundColor Green
    Write-Host "Please download and install from: https://github.com/intel/linux-npu-driver/releases" -ForegroundColor Yellow

    Write-Host ""
    Write-Host "[5/6] Installing OpenVINO..." -ForegroundColor Green
    $openvinoUrl = "https://storage.openvinotoolkit.org/repositories/openvino/packages/2024.0/windows/w_openvino_toolkit_windows_2024.0.0.14509.34caeefd078_x86_64.zip"
    $openvinoZip = "$env:TEMP\openvino.zip"
    Invoke-WebRequest -Uri $openvinoUrl -OutFile $openvinoZip
    Expand-Archive -Path $openvinoZip -DestinationPath "C:\Program Files\Intel\openvino" -Force

    Write-Host ""
    Write-Host "[6/6] Cloning and building llama.cpp..." -ForegroundColor Green
    if (!(Test-Path "C:\dev")) { New-Item -Path "C:\dev" -ItemType Directory }
    Set-Location "C:\dev"

    if (Test-Path "llama-cpp-turboquant") {
        Set-Location "llama-cpp-turboquant"
        git pull
    } else {
        git clone https://github.com/TheTom/llama-cpp-turboquant.git
        Set-Location "llama-cpp-turboquant"
    }

    git checkout feature/turboquant-kv-cache

    cmake -B build -G Ninja `
        -DCMAKE_BUILD_TYPE=Release `
        -DGGML_OPENVINO=ON `
        -DGGML_CUDA=ON `
        -DGGML_CURL=ON

    cmake --build build --parallel
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Download a GGUF model to the 'models' directory" -ForegroundColor Yellow
Write-Host "2. Update MODEL_NAME in configs/weak-openvino-npu.env" -ForegroundColor Yellow
Write-Host "3. Run: cd docker/weak-llamacpp-turboquant && docker-compose up -d" -ForegroundColor Yellow
Write-Host "4. Access API at: http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
