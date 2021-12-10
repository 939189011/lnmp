#!/bin/sh
#
#Date:2021.12.09
#Author:GZ
#Mail:V2board@qq.com

process()
{
install_date="Lnmp_install_$(date +%Y-%m-%d_%H:%M:%S).log"
printf "
\033[36m#######################################################################
#                     欢迎使用LNMP一键部署脚本                        #
#                脚本适配环境CentOS7+/RetHot7+、内存1G+               #
#                更多信息请访问 https://gz1903.github.io              #
#######################################################################\033[0m
"

while :; do echo
    read -p "请输入Mysql数据库root密码: " Database_Password 
    [ -n "$Database_Password" ] && break
done

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                  正在关闭SElinux策略 请稍等~                        #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
setenforce 0
#临时关闭SElinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
#永久关闭SElinux

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                  正在配置Firewall策略 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
#放行TCP80、443端口

# 安装 EPEL ( Extra Packages for Enterprise Linux ) YUM 源，用以解决部分依赖包不存在的问题
yum install -y epel-release

# 导入后安装 CentOS 7 的 MySQL RPM 包
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm

# 安装 PHP RPM (remi) 包
rpm -Uvh http://remi.mirrors.arminco.com/enterprise/remi-release-7.rpm

# 安装 Nginx RPM 包
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

sed -i "/remi\/mirror/{n;s/enabled=0/enabled=1/g}" /etc/yum.repos.d/remi.repo
sed -i "/test\/mirror/{n;n;s/enabled=0/enabled=1/g}" /etc/yum.repos.d/remi.repo
sed -i "/php70\/mirror/{n;s/enabled=0/enabled=1/g}" /etc/yum.repos.d/remi-php70.repo
sed -i "/php70\/mirror/{n;s/PHP 7.0 RPM/PHP 7.3 RPM/g}" /etc/yum.repos.d/remi-php70.repo
sed -i "s/7.0/7.3/g" /etc/yum.repos.d/remi-php70.repo
sed -i "s/php70/php73/g" /etc/yum.repos.d/remi-php70.repo

# 清除并生成 YUM 缓存使之生效
yum clean all
yum makecache

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                 正在安装Nginx、Mysql、PHP 请稍等~                   #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"

# 安装nmp
yum install -y mysql-community-server nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-pgsql php-recode php-snmp php-soap php-xml php-pecl-zip php-xmlrpc php-json php-redis php-mysql php-curl php-bz2 php-ioncube-loader php-process

# 启动nmp
systemctl start php-fpm.service mysqld 

# 加入开机启动
systemctl enable php-fpm.service mysqld nginx

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                 正在安装redis 请稍等~                               #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"

# 安装redis
yum -y install redis 

# 启动redis
systemctl start redis

# redis开机启动
systemctl enable redis

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                   正在配置Mysql数据库 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
mysqladmin -u root password "$Database_Password"
echo "---mysqladmin -u root password "$Database_Password""
#修改数据库密码

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在配置PHP.ini 请稍等~                          #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 600/" /etc/php.ini
sed -i "s/max_input_time = 60/max_input_time = 600/" /etc/php.ini
sed -i "s#;date.timezone =#date.timezone = Asia/Shanghai#" /etc/php.ini
# 配置php-sg11
mkdir -p /sg
wget -P /sg/  https://cdn.jsdelivr.net/gh/gz1903/sg11/Linux%2064-bit/ixed.7.3.lin
sed -i '$a\extension=/sg/ixed.7.3.lin' /etc/php.ini
#修改PHP配置文件
echo $?="PHP.inin配置完成完成"

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在配置Nginx 请稍等~                            #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
cp -i /etc/nginx/conf.d/default.conf{,.bak}
cat > /etc/nginx/conf.d/default.conf <<"eof"
server {
    listen       80;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    location ~ \.php$ {
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /usr/share/nginx/html/$fastcgi_script_name;
        include        fastcgi_params;
    }
}
eof

# 创建php测试文件
touch /usr/share/nginx/html/phpinfo.php
cat > /usr/share/nginx/html/phpinfo.php <<eos
<?php
	phpinfo();
?>
eos

#获取主机内网ip
ip="$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')"
#获取主机外网ip
ips="$(curl ip.sb)"

systemctl restart php-fpm mysqld redis && nginx -s stop && nginx
echo $?="服务启动完成"

echo -e "\033[32m--------------------------- 安装已完成 ---------------------------\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                    Nginx 1.20.2                                     #\033[0m"
echo -e "\033[36m#                    Mysql 5.6.51                                     #\033[0m"
echo -e "\033[36m#                    PHP   7.3.33                                     #\033[0m"
echo -e "\033[36m#                    redis 6.2.2                                      #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[32m 数据库用户名   :root\033[0m"
echo -e "\033[32m 数据库密码     :"$Database_Password
echo -e "\033[32m 网站目录       :/usr/share/nginx/html \033[0m"
echo -e "\033[32m 配置文件目录   :/etc/nginx/conf.d/ /etc/nginx/nginx.conf \033[0m"
echo -e "\033[32m PHP配置目录    :/etc/php.ini \033[0m"
echo -e "\033[32m 内网访问       :http://"$ip
echo -e "\033[32m 外网访问       :http://"$ips
echo -e "\033[32m 安装日志文件   :/var/log/"$install_date
echo -e "\033[32m------------------------------------------------------------------\033[0m"
echo -e "\033[32m 如果安装有问题请反馈安装日志文件。\033[0m"
echo -e "\033[32m 使用有问题请在这里寻求帮助:https://gz1903.github.io\033[0m"
echo -e "\033[32m 电子邮箱:v2board@qq.com\033[0m"
echo -e "\033[32m------------------------------------------------------------------\033[0m"

}
LOGFILE=/var/log/"Lnmp_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-


