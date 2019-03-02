#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install software-properties-common gnupg2 openssh-server curl -yq
sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
add-apt-repository -y ppa:timescale/timescaledb-ppa
apt-get update -yq && apt-get upgrade -yq
printf "12\n5\n" | apt-get install -y timescaledb-postgresql-11
timescaledb-tune --quiet --yes
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '10.0.2.55'/g" /etc/postgresql/11/main/postgresql.conf
sed -i "s/# IPv4 local connections:/host    all             all             10.0.2.0\/24             md5/g" /etc/postgresql/11/main/pg_hba.conf
service postgresql restart
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'p@ssw0rd';\""
su - postgres -c "PGPASSWORD='p@ssw0rd' psql -U postgres -c \"CREATE DATABASE webhook;\""
su - postgres -c "PGPASSWORD='p@ssw0rd' psql -U postgres -c \"CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;\" webhook"
su - postgres -c "PGPASSWORD='p@ssw0rd' psql -U postgres -c \"CREATE TABLE example_data (first_data INT not null, second_data INT not null, time TIMESTAMP not null);\" webhook"
su - postgres -c "PGPASSWORD='p@ssw0rd' psql -U postgres -c \"SELECT create_hypertable ('example_data', 'time', chunk_time_interval => interval '1 minute');\" webhook"
service ssh start
