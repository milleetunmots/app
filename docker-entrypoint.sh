#!/bin/bash
set -euo pipefail

rm -rf tmp

echo "Running yarn install to update yarn.lock"
yarn install

echo "Running bundle install to update Gemfile.lock"
bundle install

# parse DATABASE_URL
proto="$(echo $DATABASE_URL | grep :// | sed -e's,^\(.*://\).*,\1,g')"
url="$(echo ${DATABASE_URL/$proto/})"
user="$(echo $url | grep @ | cut -d@ -f1)"
host_with_port="$(echo ${url/$user@/} | cut -d/ -f1)"
port="$(echo $host_with_port | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
host="$(echo ${host_with_port/:$port/})"

echo "Waiting for pg:" $proto$url
dockerize -wait tcp://$host:$port -timeout 1m

sleep 2
DO_RUN_DB_MIGRATE=${RUN_DB_MIGRATE:-1}
if [ $DO_RUN_DB_MIGRATE -ne 0 ]; then
    echo "Running migrations..."
    bundle exec rails db:migrate
fi

echo "Rebuild indexes"
bundle exec rails pg_search:multisearch:rebuild[Child]
bundle exec rails pg_search:multisearch:rebuild[Parent]

echo "$@"
eval "$@"
