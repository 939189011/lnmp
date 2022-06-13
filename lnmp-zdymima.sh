#!/bin/bash
echo "
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                   一键YUM部署LNMP                  #
#                   本脚本由qdx提供                   #
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
"
#定义颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[36m'
plain='\033[0m'
echo -e "${yellow}
+-----------------------------------------------------+
| 适合Centos7_x86_64以上系统                           |
| Nginx version: nginx/1.20.2                         |
| Mysql version: Distrib 5.7.36                       |
| PHP version: PHP 7.1.33                             |
+-----------------------------------------------------+
${plain}"
while :; do echo
    read -p "请输入Mysql数据库root密码: " Database_Password 
    [ -n "$Database_Password" ] && break
done

System_yum() {
echo -e "${blue}
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                    #
#            一·配置CentOS 软件yum源                  #
#                                                    # 
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
${plain}"
yum install wget -y  #安装下载工具wget
# 安装 EPEL ( Extra Packages for Enterprise Linux ) YUM 源，用以解决部分依赖包不存在的问题
yum install -y epel-release
# 安装Nginx  yum
yum localinstall  -y http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

status_nginx=` yum repolist enabled |grep "nginx*" |wc -l `
if [ $status_nginx != 0 ];then
   echo -e "${green}Nginx YUM 已经正常安装 ${plain}"
else
   echo -e "${red} Nginx YUM 未能正常安装，请查看日志 ${plain}"
fi
#安装php7.1源
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
status_php=` yum repolist enabled |grep "webtatic*" |wc -l `
if [ $status_php != 0 ];then
   echo -e "${green}PHP  YUM 已经正常安装 ${plain}"
else
   echo -e "${red} PHP YUM 未能正常安装，请查看日志 ${plain}"
fi
# 安装MySQL源
yum -y localinstall http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
sed -i "s/gpgcheck=1/gpgcheck=0/g"  /etc/yum.repos.d/mysql-community.repo
status_mysql=` yum repolist enabled |grep "mysql.*-community.*" |wc -l `
if [ $status_mysql != 0 ];then
   echo -e "${green} Mysql YUM 已经正常安装 ${plain}"
else
   echo -e "${red} Mysql YUM 未能正常安装，请查看日志 ${plain}"
fi

#wget http://www.atomicorp.com/installers/atomic #下载atomic yum源 含有nginx包
#sh ./atomic   #安装
#yum check-update #更新yum软件包
echo -e "${green}
+------------------------------+
|         关闭SElinux          |
+------------------------------+
${plain}"
#临时关闭SElinux
setenforce 0
#永久关闭SElinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
echo $? = "关闭SElinux策略"
echo -e "${yellow}
+------------------------------+
|     1. 安装开发包和库文件      |
+------------------------------+
${plain}"

 yum -y install ntp make vim openssl openssl-devel pcre pcre-devel libpng libpng-devel libjpeg-6b libjpeg-devel-6b freetype freetype-devel gd gd-devel zlib zlib-devel gcc gcc-c++ libXpm libXpm-devel ncurses ncurses-devel libmcrypt libmcrypt-devel libxml2 libxml2-devel imake autoconf automake screen sysstat compat-libstdc++-33 curl curl-devel lsof

}

Nginx() {

echo -e "${blue}
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                    #
#           二.开始对服务器系统安装Nginx服务           #
#                                                    # 
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
${plain}"

yum install nginx -y

echo -e "${yellow}
+------------------------------+
|          1.启 动 程 序        |
+------------------------------+
${plain}"
systemctl start nginx.service
echo $? = "启动Nginx"

echo -e "${yellow}
+------------------------------+
|        2. 检 查 服 务         |
+------------------------------+
${plain}"
status=`lsof -i:80|awk '{print $1}'|grep -w nginx|wc -l`
if [ $status != 0 ];then
   echo -e "${green}Nginx服务器已经正常启动${plain}"
   echo "放行服务监听端口"
      firewall-cmd --zone=public --add-port=80/tcp --permanent
      firewall-cmd --reload
else
   echo -e "${red} Nginx服务未能正常启动，请查看日志 ${plain}"
fi
systemctl enable nginx.service
echo $? = "开机自启动Nginx"
}

MySQL() {
echo -e "${blue}
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                    #
#           三.开始对服务器系统安装MySQL服务           #
#                                                    # 
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
${plain}"

yum -y install mysql-community-server  mysql-community-devel
 
echo -e "${yellow}
+------------------------------+
|        1. 启 动 程 序         |
+------------------------------+
${plain}"
 
systemctl start mysqld
echo $? = "启动MySQL"
echo -e "${yellow}
+------------------------------+
|        2. 检 查 服 务         |
+------------------------------+
${plain}"
 
status=`lsof -i:3306|awk '{print $1}'|grep -w mysqld|wc -l`
if [ $status != 0 ];then
   echo -e "${green}MySQL服务器已经正常启动${plain}"
   echo "放行服务监听端口"
      firewall-cmd --zone=public --add-port=3306/tcp --permanent
      firewall-cmd --reload
else
   echo -e "${red} MySQL服务未能正常启动，请查看日志 ${plain}"
fi
systemctl enable mysqld
echo $? = "开机自启动MySQL"
#修改数据库登录密码
sleep 1

defaultmysqlpwd=`grep 'A temporary password' /var/log/mysqld.log | awk -F "root@localhost: " '{ print $2}' `

/usr/bin/mysql -uroot -p${defaultmysqlpwd} --connect-expired-password << EOF

set global validate_password_policy = 0;

set global validate_password_length = 4;

SET PASSWORD = PASSWORD('$Database_Password');

grant all privileges on *.* to root@'%' identified by '$Database_Password';

EOF

sleep 1

service mysqld restart

}

Php() {
echo -e "${blue}
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                    #
#           四.开始对服务器系统安装PHP服务             #
#                                                    # 
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
${plain}"

yum -y install php71w php71w-fpm  php71w-mbstring php71w-common php71w-gd php71w-mcrypt php71w-mysql php71w-xml php71w-cli php71w-devel php71w-pecl-memcached php71w-pecl-redis php71w-opcache
echo -e "${yellow}
+------------------------------+
|          1.启 动 程 序        |
+------------------------------+
${plain}"
systemctl start php-fpm.service
echo $? = "启动PHP"

echo -e "${yellow}
+------------------------------+
|        2. 检 查 服 务         |
+------------------------------+
${plain}"
status=`lsof -i:9000|awk '{print $1}'|grep -w php-fpm|wc -l`
if [ $status != 0 ];then
   echo -e "${green}PHP服务器已经正常启动 ${plain}"
   echo "放行服务监听端口"
      firewall-cmd --zone=public --add-port=9000/tcp --permanent
      firewall-cmd --reload
else
   echo -e "${red} PHP服务未能正常启动，请查看日志 ${plain}"
fi
systemctl enable php-fpm.service
echo $? = "开机自启动PHP"

}

 
Peizhi() {
echo -e "${blue}
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
#                                                    #
#           五.配置nginx支持php,配置php               #
#                                                    # 
#++++++++++++++++++++++++++++++++++++++++++++++++++++#
${plain}"
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sed -i "s/user  nginx;/user  nginx nginx;/g" /etc/nginx/nginx.conf
echo $? = "修改nginx.conf文件"
sed -i "s/expose_php = On/expose_php = Off/g"  /etc/php.ini
echo $? = "修改pho.ini文件"
cp /etc/nginx/conf.d/default.conf{,.bak} 
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen       80;
    server_name  localhost;
    location / {
        root   /usr/share/nginx/html;
        index  index.php index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
    location ~ \.php$ {
        root           /usr/share/nginx/html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /usr/share/nginx/html/\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
EOF
echo $? = "修改default.conf文件"
systemctl restart nginx.service
systemctl restart php-fpm.service
echo $? = "重启nginx,php 服务"
# 创建php web测试文件
cd /usr/share/nginx/html/
touch index.php
cat >> index.php << EOF
<?php
     phpinfo();
?>
EOF
chown nginx.nginx /usr/share/nginx/html/ -R  #设置目录所有者
chmod -Rf 777 /usr/share/nginx/html
echo -e "${yellow}
+-----------------------------------------------------+
| nginx默认站点目录是：/usr/share/nginx/html/          |
| 权限设置：chown nginx.nginx/usr/share/nginx/html/ -R |
| MySQL数据库目录是：/var/lib/mysql                    |
| 权限设置：chown mysql.mysql -R /var/lib/mysql        | 
+-----------------------------------------------------+
${plain}"
echo -e "${red}MySQL root密码：${plain}"$Database_Password 

}

main() {
	System_yum
	Nginx
	MySQL
	Php
	Peizhi
}
main
