#!/usr/bin/env bash

docker stop $(docker ps -aq)

docker system prune -a -f

# Now that all images should be gone we can delete all volumes.
docker volume prune -f

