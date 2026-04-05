# Installation script for strong PC setup (Windows 11)
# vLLM with maximum performance

# Requires Administrator privileges
#Requires -RunAsAdministrator

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "AI-unclove Strong PC Setup Installation" -ForegroundColor Cyan
Write-Host "vLLM with OpenAI-compatible API" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if running in WSL2 is preferred
Write-Host "[INFO] This script requires WSL2 for optimal performance" -ForegroundColor Yellow
Write-Host ""

Write-Host "[1/5] Checking WSL2 installation..." -ForegroundColor Green

if (!(wsl --list --verbose)) {
    Write-Host "Installing WSL2..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-22.04
    Write-Host "WSL2 installed. Please restart and run this script again." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "[2/5] Checking Docker Desktop..." -ForegroundColor Green
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop
    Write-Host "Docker Desktop installed. Please start Docker Desktop and run this script again." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "[3/5] Verifying NVIDIA GPU and drivers..." -ForegroundColor Green
if (!(nvidia-smi)) {
    Write-Host "Installing NVIDIA drivers..." -ForegroundColor Yellow
    Write-Host "Please download and install from: https://www.nvidia.com/Download/index.aspx" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "[4/5] Installing CUDA Toolkit..." -ForegroundColor Green
if (!(Get-Command nvcc -ErrorAction SilentlyContinue)) {
    $cudaUrl = "https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda_12.3.0_545.23.06_windows.exe"
    $cudaInstaller = "$env:TEMP\cuda_installer.exe"

    Write-Host "Downloading CUDA Toolkit..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $cudaUrl -OutFile $cudaInstaller

    Write-Host "Installing CUDA Toolkit..." -ForegroundColor Yellow
    Start-Process -FilePath $cudaInstaller -ArgumentList "-s" -Wait
}

Write-Host ""
Write-Host "[5/5] Setting up Docker network..." -ForegroundColor Green
docker network create llm-network 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Network already exists or created successfully" -ForegroundColor Gray
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Download a HuggingFace model to the 'models' directory" -ForegroundColor Yellow
Write-Host "2. Update MODEL_NAME in configs/strong-vllm.env" -ForegroundColor Yellow
Write-Host "3. Run: cd docker/strong-vllm && docker-compose up -d" -ForegroundColor Yellow
Write-Host "4. Access API at: http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "For GUI, install Open WebUI:" -ForegroundColor Yellow
Write-Host "cd docker/open-webui && docker-compose up -d" -ForegroundColor Yellow
Write-Host "Access at: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
