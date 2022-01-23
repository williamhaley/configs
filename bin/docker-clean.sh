#!/usr/bin/env bash

CONTAINERS=$(docker ps -a --format "{{.ID}}")

for C in "$CONTAINERS"
do
	docker rm -f $C
done

