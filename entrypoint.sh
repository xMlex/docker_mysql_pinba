#!/bin/bash -e

export dataDir=/opt/mysql/data

groupadd -r mysql && useradd -r -g mysql mysql
chown -R mysql:mysql ${dataDir}

su - mysql -m -c "/run.sh"

