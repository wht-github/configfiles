# nb container

This setup allows you to use [nb](https://github.com/xwmx/nb) (a command-line note-taking tool) via Docker, with notes stored on your Windows host.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.

## Usage

### 1. Build the image
```powershell
docker compose build
```

### 2. Run nb
You can run `nb` commands using docker compose:
```powershell
docker compose run --rm nb help
```

### 3. Create a note
```powershell
docker compose run --rm nb add "Hello from Windows"
```

## Note Storage
Your notes and configuration are stored in the `./notes` directory within this folder, which is mounted to `/root/.nb` inside the container. 

- **Global Availability**: Since it's mounted to the default `~/.nb` location, `nb` will recognize these notes regardless of the working directory.
- **Windows Access**: You can edit the markdown files directly from Windows (e.g., in `notes/home/`) using VS Code.

## Tips
If you want to use `nb` more easily, you can add an alias or a function to your PowerShell profile:
```powershell
function nb { docker compose -f "D:\Workspace\configfiles\containers\nb-container\docker-compose.yml" run --rm nb $args }
```
