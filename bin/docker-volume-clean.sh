#!/usr/bin/env bash

# Prune all volumes not used in at least one image.
docker volume prune -f

