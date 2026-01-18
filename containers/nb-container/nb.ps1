#!/usr/bin/env pwsh
# Helper script to run nb via docker-compose

# Since the entrypoint is now bash, we explicitly call the nb command
docker compose run --rm nb nb $args
