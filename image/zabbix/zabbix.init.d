#!/bin/bash

###
# Database
###

DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
DB_TYPE=${DB_TYPE:-}

# MySQL
if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
  DB_TYPE=MYSQL
  DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}

  DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
fi

# Postgres
if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
  DB_TYPE=POSTGRESQL
  DB_HOST=${DB_HOST:-${POSTGRES_PORT_5432_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${POSTGRES_PORT_5432_TCP_PORT}}

  DB_USER=${DB_USER:-${POSTGRES_ENV_POSTGRES_USER}}
  DB_PASS=${DB_PASS:-${POSTGRES_ENV_POSTGRES_PASSWORD}}
  DB_NAME=${DB_NAME:-${POSTGRES_ENV_POSTGRES_USER}}  
fi

if [ -z "${DB_TYPE}" ]; then
  echo "You have to link to a mysql or postgres container, or inform the database type and configuration via environment variables."
  exit 1
fi

ZBX_SERVER=${ZBX_SERVER:-}
ZBX_SERVER_PORT=${ZBX_SERVER_PORT:-10051}
ZBX_SERVER_NAME=${ZBX_SERVER_NAME:-zabbix_server}

###
# Zabbix Server
###

if [ -n ${ZBX_PORT_10051_TCP_ADDR} ]; then
  ZBX_SERVER=${ZBX_PORT_10051_TCP_ADDR}
  ZBX_SERVER_PORT=${ZBX_PORT_10051_TCP_PORT}
fi

cat >/etc/zabbix/web/zabbix.conf.php <<EOF
<?php
// Zabbix GUI configuration file
global \$DB;

\$DB['TYPE']     = '${DB_TYPE}';
\$DB['SERVER']   = '${DB_HOST}';
\$DB['PORT']     = '${DB_PORT}';
\$DB['DATABASE'] = '${DB_NAME}';
\$DB['USER']     = '${DB_USER}';
\$DB['PASSWORD'] = '${DB_PASS}';

// SCHEMA is relevant only for IBM_DB2 database
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = '${ZBX_SERVER}';
\$ZBX_SERVER_PORT = '${ZBX_SERVER_PORT}';
\$ZBX_SERVER_NAME = '${ZBX_SERVER_NAME}';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF

###
# Web
###

SERVER_NAME=${SERVER_NAME:-localhost}

cat > /etc/nginx/sites-enabled/zabbix.conf <<EOF
server {
        listen 80;
        server_name ${SERVER_NAME};
        root /usr/share/nginx/html/zabbix;
        index index.php;

        location ~ \\.php\$ {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index  index.php;
                #fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
                fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include        fastcgi_params;
        }

}
EOF
