#!/usr/bin/env pwsh
# Run script for agent container with DeepSeek API

param(
    [string]$WorkspacePath = $PWD,
    [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [string]$ContainerName,
    [string]$ImageName = "agent-container:latest"
)

# Resolve and validate workspace path
$WorkspacePath = Resolve-Path -Path $WorkspacePath -ErrorAction SilentlyContinue
if (-not $WorkspacePath -or -not (Test-Path $WorkspacePath)) {
    Write-Host "Error: Workspace path does not exist: $WorkspacePath" -ForegroundColor Red
    exit 1
}

# Generate container name based on workspace path if not provided
if ([string]::IsNullOrEmpty($ContainerName)) {
    $workspaceName = Split-Path -Leaf $WorkspacePath
    $ContainerName = "agent-$workspaceName"
}

# Check if API key is provided
if ([string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "Error: DEEPSEEK_API_KEY not provided" -ForegroundColor Red
    Write-Host "Usage: .\run.ps1 -ApiKey YOUR_API_KEY" -ForegroundColor Yellow
    Write-Host "   or: Set `$env:DEEPSEEK_API_KEY and run .\run.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if container already exists
$existing = podman ps -a --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($existing -eq $ContainerName) {
    Write-Host "Container '$ContainerName' already exists. Starting it..." -ForegroundColor Yellow
    podman start -ai $ContainerName
} else {
    # Run new container
    Write-Host "Creating and starting container: $ContainerName" -ForegroundColor Green
    Write-Host "Mounting workspace: $WorkspacePath" -ForegroundColor Cyan
    podman run -it `
        --name $ContainerName `
        -e DEEPSEEK_API_KEY=$ApiKey `
        -v "${WorkspacePath}:/workspace" `
        $ImageName
    
    Write-Host "Container exited. Use 'podman start -ai $ContainerName' to restart." -ForegroundColor Cyan
}
