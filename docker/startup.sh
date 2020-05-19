#! /bin/sh
./docker/wait-for-services.sh
./docker/prepare-db.sh
rm -rf ./tmp/pids && mkdir -p ./tmp/pids
echo "Starting puma..."
bin/rails server --port 3000 --binding 0.0.0.0
