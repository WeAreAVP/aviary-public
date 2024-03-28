#!/bin/bash
set -e

context_exists=$(docker context ls --format "{{.Name}}" | grep -w "aviary-ecs")

if [ -n "$context_exists" ]; then
  printf "Context aviary-ecs exists. \n switching to context"
  docker context use aviary-ecs
else
  printf "Context aviary-ecs does not exist. \n Creating context... \n Please follow instructions \n"
  docker context create ecs aviary-ecs
fi

echo "Deploying the currently hosted images and the docker-compose file available in root"
docker-compose -f docker-compose.prod.yml up

echo "Deployment completed, switching back to default docker context..."
docker context use default