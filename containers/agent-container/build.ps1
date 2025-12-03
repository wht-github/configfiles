#!/usr/bin/env pwsh
# Build script for agent container

param(
    [string]$ImageName = "agent-container:latest"
)

Write-Host "Building container image: $ImageName" -ForegroundColor Green
podman build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Build successful!" -ForegroundColor Green
