#!/bin/bash
echo '==开始安装mysql=='
# 得到当前脚本所在绝对路径
DIR=$( cd ${0%/*} && pwd )
useradd mysql -s /sbin/nologin -M
tar -zxvf $DIR/mysql-5.7.43-linux-glibc2.12-x86_64.tar.gz -C $DIR/
mv $DIR/mysql-5.7.43-linux-glibc2.12-x86_64 /usr/local/mysql-5.7.43
ln -s /usr/local/mysql-5.7.43  /usr/local/mysql
rpm -e --nodeps mariadb-libs
cat >/etc/my.cnf<<EOF
[mysqld]
character-set-server=utf8mb4
basedir = /usr/local/mysql/
datadir = /usr/local/mysql/data
socket = /tmp/mysql.sock
server_id = 1
port = 13306
log_error = /usr/local/mysql/data/dcs_mysql.err
lower_case_table_names = 1
max_allowed_packet=64M
log_bin_trust_function_creators = ON
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
wait_timeout= 180
interactive_timeout=  180

# 开启慢查询1为启用，0为禁用  
slow_query_log = 1
# 开启慢查询时间，此处为1秒，达到此值才记录数据
long_query_time = 3
# 检索行数达到此数值，才记录慢查询日志中
min_examined_row_limit = 100
# 设定每分钟记录到日志的未使用索引的语句数目，超过这个数目后只记录语句数量和花费的总时间
log_throttle_queries_not_using_indexes = 10
# 慢查询日志文件地址
slow_query_log_file = /usr/local/mysql/logs/mysql-slow.log
# 开启记录没有使用索引查询语句
log-queries-not-using-indexes = 1
#5.7版本新增时间戳所属时区参数，默认记录UTC时区的时间戳到慢查询日志，应修改为记录系统时区 
log_timestamps=system

[client]
default-character-set=utf8mb4
socket = /tmp/mysql.sock

[mysql]
socket = /tmp/mysql.sock
prompt = rstyro_mysql>
EOF
yum install libaio-devel -y
# rpm -ivh /opt/libaio-devel-0.3.12-1.i386.rpm
mkdir -p /usr/local/mysql/data
chown -R mysql.mysql /usr/local/mysql/
/usr/local/mysql/bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data
cat >/etc/systemd/system/mysqld.service<<EOF
[Unit]
Description=MySQL Server by dcs
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
EOF
systemctl start mysqld
systemctl enable mysqld
netstat -lntup|grep mysql
ps -ef|grep mysql|grep -v grep
echo 'export PATH=/usr/local/mysql/bin:$PATH' >>/etc/profile
source  /etc/profile
mysqladmin -u root password 'rstyro123456'
echo '==结束安装mysql=='