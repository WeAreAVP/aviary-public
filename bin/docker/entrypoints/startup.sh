#! /bin/sh
echo "Starting puma..."
bin/rails server --port 3000 --binding 0.0.0.0
