#! /bin/sh
echo "wait-for-services.sh is executing..."
# Wait for MySQL
until nc -z -v -w30 "$DB_HOST" 3306
do
  echo 'Waiting for MySQL...'
  sleep 1
done
echo "MySQL is up and running"

# Wait for Solr
until nc -z -v -w30 "$SOLR_HOST" 8983
do
  echo 'Waiting for Solr...'
  sleep 1
done
echo "Solr is up and running"

# Wait for Redis
until nc -z -v -w30 "$REDIS_SERVER" 6379
do
  echo 'Waiting for Redis...'
  sleep 1
done
echo "Redis is up and running"
