#! /bin/sh
echo "prepare-db.sh is executing..."
# If database exists, migrate. Otherwise setup (create and seed)
bin/rails db:migrate 2>/dev/null || bin/rails db:setup
echo "Migrations executed!"
