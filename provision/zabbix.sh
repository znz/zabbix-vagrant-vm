#!/bin/bash
set -euxo pipefail
apt-get install -y -t jessie-backports zabbix-agent
# 10050/tcp
apt-get install -y pwgen
apt-get install -y nginx
apt-get install -y php5-fpm
apt-get install -y -t jessie-backports zabbix-frontend-php
if ! grep -q zabbix /etc/nginx/sites-available/default; then
  sed -i -e '/^}$/{i\
'$'\t''include /usr/share/doc/zabbix-frontend-php/examples/nginx.conf;
}' /etc/nginx/sites-available/default
  service nginx reload
  etckeeper commit 'Add zabbix-frontend-php to nginx' || :
fi
# open http://localhost:2080/zabbix/
cp /vagrant/provision/php-local.ini /etc/php5/fpm/conf.d/50-local.ini
service php5-fpm reload
etckeeper commit 'Add php local.ini for zabbix' || :
apt-get install -y -t jessie-backports zabbix-server-pgsql
#提案パッケージ:
#  liblinear-tools liblinear-dev libmyodbc odbc-postgresql tdsodbc unixodbc-bin lm-sensors snmp-mibs-downloader
#  postgresql-doc oidentd ident-server locales-all postgresql-doc-9.4 python-lxml-dbg snmptrapd openssl-blacklist
if ! [[ "$(sudo -u postgres psql -l)" =~ zabbix ]]; then
  sudo -u postgres createdb zabbix
  # createuser without -P
  sudo -u postgres createuser -SDR zabbix
  export PGPASSWORD=$(pwgen -s 32)
  sudo -u postgres psql -c "alter role zabbix with password '$PGPASSWORD';"
  zcat /usr/share/zabbix-server-pgsql/{schema,images,data}.sql.gz | psql -h localhost zabbix zabbix
  service zabbix-server start
  cat >/etc/zabbix/zabbix.conf.php <<EOF
<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'POSTGRESQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '$PGPASSWORD';

// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = 'Zabbix3';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF
  chgrp www-data /etc/zabbix/zabbix.conf.php
  chmod 640 /etc/zabbix/zabbix.conf.php
  cat >/etc/zabbix/zabbix_server.conf.d/local.conf <<EOF
DBPassword=$PGPASSWORD
EOF
  chgrp zabbix /etc/zabbix/zabbix_server.conf.d/local.conf
  chmod 640 /etc/zabbix/zabbix_server.conf.d/local.conf
  systemctl enable zabbix-server.service
  systemctl restart zabbix-server.service
  cat >/home/vagrant/.pgpass <<EOF
localhost:5432:zabbix:zabbix:$PGPASSWORD
EOF
  chown vagrant:vagrant /home/vagrant/.pgpass
  chmod 600 /home/vagrant/.pgpass
  etckeeper commit 'Setup zabbix database' || :
fi

apt-get install -y -t jessie-backports fonts-noto-cjk
ln -snf /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc /usr/share/zabbix/fonts/DejaVuSans.ttf
apt-get install -y jq
install -D /vagrant/provision/sslnotafter.rb /etc/zabbix/externalscripts/sslnotafter.rb
etckeeper commit 'Add externalscripts of zabbix' || :

install /vagrant/nadoka/notice.rb /etc/zabbix/alert.d/notice.rb
install -m644 /vagrant/nadoka/sudoers /etc/sudoers.d/nadoka
etckeeper commit 'Add alert script of zabbix' || :

install /vagrant/provision/local-zabbix-dump /etc/cron.daily/local-zabbix-dump
etckeeper commit 'Add backup script' || :
