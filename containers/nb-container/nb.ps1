#!/usr/bin/env pwsh
# Helper script to run nb via docker-compose

# Since the entrypoint is now bash, we explicitly call the nb command
# --service-ports is required to map ports (like 6789) when using 'run'
docker compose run --rm --service-ports nb nb $args
