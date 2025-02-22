#!/bin/bash
export DOCKER_CLIENT_TIMEOUT=3000
export COMPOSE_HTTP_TIMEOUT=3000
echo $DOCKER_CLIENT_TIMEOUT 
#docker-compose build
# Extract image names from docker-compose.yml
images=$(grep 'image:' docker-compose.yml | awk '{print $2}')
N=8
# Push each image
for ((i=0; i<N; i++)); do
    for image in $images; do
        echo "Pushing $image..."
        docker push $image
    done
done 

echo "All images have been pushed."
