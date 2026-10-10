#!/usr/bin/env bash

set -ex

# this makes sure that this script always runs in its own directory so that it pulls
# the right `.env`, for instance (this should also be an absolute path)
script_path="$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")"
cd "$script_path"

source ./.env

chmod +x ./sync_dotenvs.sh
sudo -u "#$HOST_NONROOT_UID" bash ./sync_dotenvs.sh

# try this in our current directory first in case the services to restart were started by
# this project originally
docker compose --profile "$DOCKER_DEFAULT_PROFILE" down

# otherwise (e.g. if they were started by a nested docker project), we do a project-agnostic restart
# SYNC: containers!
docker stop nginx && docker rm -v nginx
docker stop iocaine && docker rm -v iocaine
docker stop file_server && docker rm -v file_server
docker stop file_server_anubis && docker rm -v file_server_anubis

docker system prune --force

if [[ "$1" == "-d" ]]; then
    docker compose --profile "$DOCKER_DEFAULT_PROFILE" up --build -d
else
    docker compose --profile "$DOCKER_DEFAULT_PROFILE" up --build
fi
