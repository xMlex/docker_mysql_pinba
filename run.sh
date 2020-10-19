#!/bin/bash -e

PATH="$PATH:/opt/mysql:/opt/mysql/scripts:/opt/mysql/bin"
export dataDir=/opt/mysql/data

cd /opt/mysql

if [ ! -d "$dataDir/mysql" ]; then
  echo "Initializing database in $dataDir"
  mysql_install_db --user=mysql --datadir=$dataDir
  echo 'Database initialized'

  if [ -z ${MYSQL_ROOT_PASSWORD+x} ] || [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
    export MYSQL_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
  fi
  echo "SET ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"

  echo 'Initialize pinba extension ...'
  socket="/tmp/mysql.sock"
  mysqld --skip-networking --socket="${socket}" &
  pid="$!"
  mysql=(mysql --protocol=socket -u root -h localhost --socket="${socket}")

  for i in {10..0}; do
    if echo 'SELECT 1' | "${mysql[@]}" &>/dev/null; then
      break
    fi
    echo 'MySQL init process in progress...'
    sleep 1
  done

  "${mysql[@]}" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			FLUSH PRIVILEGES ;
			DROP DATABASE IF EXISTS test ;
	EOSQL

  "${mysql[@]}" <<-EOSQL
			INSTALL PLUGIN pinba SONAME 'libpinba_engine.so';
			CREATE DATABASE pinba;
	EOSQL

  "${mysql[@]}" -D pinba </opt/default_tables.sql
  echo 'Pinba extension initialized'
  if ! kill -s TERM "$pid" || ! wait "$pid"; then
    echo >&2 'MySQL init process failed.'
    exit 1
  fi

  echo
  echo 'MySQL init process done. Ready for start up.'
  echo
fi
echo "Starting database in directory: $dataDir"
exec mysqld --defaults-file="/etc/my.cnf" --datadir=$dataDir
