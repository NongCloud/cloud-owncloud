#!/bin/bash
#nong-v 2019-01-23 install LAMP and owncloud 

#Package Download URL
HTTPD_URL=https://mirrors.tuna.tsinghua.edu.cn/apache/httpd/httpd-2.4.38.tar.gz
MySQL_URL=https://cdn.mysql.com//Downloads/MySQL-5.6/mysql-5.6.43.tar.gz
PHP_URL=http://cn.php.net/distributions/php-5.6.40.tar.gz
ICU_URL=http://download.icu-project.org/files/icu4c/51.2/icu4c-51_2-src.tgz
APR_URL=https://archive.apache.org/dist/apr/apr-1.5.2.tar.gz
APR_UTIL_URL=https://archive.apache.org/dist/apr/apr-util-1.5.4.tar.gz
OWNCLOUD_URL=https://download.owncloud.org/community/owncloud-10.0.10.zip
#Package name
HTTPD_GZ=httpd-2.4.38.tar.gz
MySQL_GZ=mysql-5.6.43.tar.gz
PHP_GZ=php-5.6.40.tar.gz
ICU_GZ=icu4c-51_2-src.tgz
APR_GZ=apr-1.5.2.tar.gz
APR_UTIL_GZ=apr-util-1.5.4.tar.gz
OWNCLOUD_ZIP=owncloud-10.0.10.zip
gcc(){
	rpm -q epel-release 
	[ $? -ne 0 ] && yum install epel-release -y && yum clean all && yum makecache
	rpm -q gcc &>/dev/null ||yum install gcc gcc-c++ -y
	rpm -q openssl-devel &>/dev/null||yum install openssl-devel -y
	rpm -q wget &>dev/null ||yum install wget -y
}
PS3="Your choice is : "
#install apache
apache(){
ls /etc/httpd/ &>/dev/null||ls /usr/local/apache/ &>/dev/null
[ $? -eq 0 ] && echo  -e "\033[31mYour system is already installed with Apache！...\033[0m" && exit
#install apache build environment apr
	cd /usr/src/apr-1.5.2/         #Enter the installation directory
if [ $? -ne 0 ];then 
	cd /tmp 
	tar -xf $APR_GZ -C /usr/src/
	[ $? -ne 0 ] && wget $APR_URL  && tar -xf $APR_GZ -C /usr/src/ 
	cd /usr/src/apr-1.5.2
fi
./configure --prefix=/usr/local/apr && make && make install
#install apache build environment apr-util
if [ $? -eq 0 ];then
	cd /usr/src/apr-util-1.5.4/ 
	if [ $? -ne 0 ];then 
		cd /tmp 
		 tar -xf $APR_UTIL_GZ -C /usr/src/
		[ $? -ne 0 ] && wget $APR_UTIL_URL && tar -xf $APR_UTIL_GZ -C /usr/src 
		cd /usr/src/apr-util-1.5.4/
	fi
	./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr &&  make && make install
fi
#install apache-2.4.38
if [ $? -eq 0 ];then
	yum install libxml2-devel bzip2-devel pcre-devel -y
	id apache ||useradd -M -s /sbin/nologin -r apache
	cd /usr/src/httpd-2.4.38/         #Enter the apache installation directory
	if [ $? -ne 0 ];then 
		cd /tmp 
		tar -xf $HTTPD_GZ -C /usr/src/
		[ $? -ne 0 ] && wget $HTTPD_URL && tar -xf $HTTPD_GZ -C /usr/src/ 
		cd /usr/src/httpd-2.4.38/
	fi
	./configure --prefix=/usr/local/apache \
--sysconfdir=/etc/httpd \
--enable-modules=all \
--enable-mods-shared=all \
--enable-so \
--enable-ssl \
--enable-cgi \
--enable-rewrite \
--with-apr=/usr/local/apr \
--with-apr-util=/usr/local/apr-util/ \
--with-pcre \
--with-libxml2 \
--with-mpm=event \
--enable-mpms-shared=all && make &&make install
fi
ls /usr/local/apache/ &>/dev/null
	if [ $? -eq 0 ];then
		echo -e "\033[32mapache install success...\033[0m"
	else
		echo -e "\033[031mapache install fail,plaese check the surroundings!\033[0m" &&exit
	fi
}
#install mysql-5.6.43
mysql(){
ls /usr/local/mysql/bin/ &>/dev/null ||rpm -q mariadb-server &>/dev/null
[ $? -eq 0 ] && echo -e "\033[31mYour system is already installed with MySQL！...\033[0m" && exit
	id mysql &>/dev/null||useradd -M -s /sbin/nologin -r mysql     #Create a mysql user
	cd /usr/src/mysql-5.6.43/ 
	if [ $? -ne 0 ];then 
		cd /tmp 
		tar -xf $MySQL_GZ -C /usr/src
		[ $? -ne 0 ] && wget $MySQL_URL && tar -xf $MySQL_GZ -C /usr/src 
		cd /usr/src/mysql-5.6.43/
	fi
#Install mysql build environment
	rpm -q cmake &>/dev/null ||yum install cmake -y
	yum install bison  ncurses  ncurses-devel perl-Data-Dumper -y
	ls /mysql/data &>/dev/null || mkdir -p /mysql/data && chown -R mysql.mysql /mysql/data
#Precompiled and compiled installation mysql
rm -rf /usr/src/mysql-5.6.43/CMakeCache.txt &>/dev/null
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
 -DMYSQL_DATADIR=/mysql/data \
 -DDEFAULT_CHARSET=utf8 \
 -DEXTRA_CHARSETS=all \
 -DDEFAULT_COLLATION=utf8_general_ci \
 -DWITH_SSL=system \
 -DWITH_EMBEDDED_SERVER=1 \
 -DENABLED_LOCAL_INFILE=1 \
 -DWITH_INNOBASE_STORAGE_ENGINE=1 \
 -DWITH_SSL=bundled  && make && make install 
ls /usr/local/mysql &>/dev/null
	if [ $? -eq 0 ];then
		echo -e "\033[32mMySQL install success...\033[0m"
#Mysql initialization
		cd /usr/local/mysql && chown -R mysql.mysql /usr/local/mysql/
		./scripts/mysql_install_db --user=mysql \
--basedir=/usr/local/mysql/ \
--datadir=/mysql/data

		cp support-files/my-default.cnf /etc/my.cnf
		cp support-files/mysql.server /etc/rc.d/init.d/mysqld
		chmod 755 /etc/rc.d/init.d/mysqld
		echo -e "[mysqld]\nsocket=/tmp/mysql.sock\n\n[client]\nsocket=/tmp/mysql.sock" >/etc/my.cnf
		/etc/rc.d/init.d/mysqld restart
		chkconfig mysqld on
		/usr/local/mysql/bin/mysqladmin -uroot password 123456
	else
		echo -e "\033[31mMySQL install fail,plaese check the surroundings!\033[0m" &&exit
	fi
}
#install php-5.6.40
php(){
ls /usr/local/apache/modules|grep -w "libphp5.so" &>/dev/null ||rpm -q php &>/dev/null
[ $? -eq 0 ] && echo -e "\033[31mYour system is already installed with PHP！...\033[0m" && exit
#PHP dependent environment installation
	yum install libpng-devel libjpeg-devel curl-devel freetype-devel -y
	cd /tmp/icu/source  
	if [ $? -ne 0 ];then
		cd /tmp && tar -zxf $ICU_GZ
		if [ $? -ne 0 ];then
			wget $ICU_URL && tar -zxf $ICU_GZ
			cd /tmp/icu/source
		fi
	fi
		./configure --prefix=/usr/local/icu && make && make install
##install php-5.6.40
	cd /usr/src/php-5.6.40/
	if [ $? -ne 0 ];then
		cd /tmp 
		tar -xf $PHP_GZ -C /usr/src 
		[ $? -ne 0 ] && wget $PHP_URL  && tar -xf $PHP_GZ -C /usr/src 
		cd /usr/src/php-5.6.40/
	fi
 ./configure --prefix=/usr/local/php \
--with-apxs2=/usr/local/apache/bin/apxs \
--with-config-file-path=/etc/ \
--with-config-file-scan-dir=/etc/php.d/ \
--with-libxml-dir \
--with-openssl \
--with-pcre-dir \
--with-jpeg-dir \
--with-zlib-dir \
--with-png-dir \
--with-freetype-dir \
--with-gd \
--enable-intl \
--with-icu-dir=/usr/local/icu \
--with-intl \
--with-curl \
--enable-mbstring \
--with-pdo-mysql=/usr/local/mysql/ \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-libxml-dir \
--enable-zip \
--enable-maintainer-zts && make && make install
ls /usr/local/apache/modules|grep -w "libphp5.so" &>/dev/null
	if [ $? -eq 0 ];then
		echo  -e "\033[32mPHP install success...\033[0m"
		cp php.ini-production /etc/php.ini
		apache_php       #Apache interacts with php
	else
		echo -e "\033[31mPHP install fail,plaese check the surroundings!\033[0m" &&exit
	fi
}
#Apache interacts with php
apache_php(){
	sed -i.bak 's/DirectoryIndex index.html/DirectoryIndex index.php index.html\n\tAddHandler php5-script .php\n\tAddType text\/html .php/g' /etc/httpd/httpd.conf
	sed -i.bak '180,190s/daemon/apache/g' /etc/httpd/httpd.conf
	sed -i.bak '/short_open_tag/s/Off/On/g;/expose_php/s/On/Off/g' /etc/php.ini
	echo -e "ServerTokens Prod\nServerSignature Off" >>/etc/httpd/httpd.conf
	pkill httpd
	/usr/local/apache/bin/httpd -k start --user=apache
}
#owncloud install
owncloud(){
rm -rf /usr/local/apache/htdosc/*
cp -r /tmp/owncloud/* /usr/local/apache/htdocs
if [ $? -ne 0 ];then
	cd /tmp && rpm -q unzip ||yum install unzip -y 
	unzip $OWNCLOUD_ZIP
	[ $? -ne 0 ] && wget $OWNCLOUD_URL && unzip $OWNCLOUD_ZIP
	cp -r /tmp/owncloud/* /usr/local/apache/htdocs/
fi
chown -R apache.apache /usr/local/apache/htdocs/
chmod 777 /usr/local/apache/htdocs/* -R
/usr/local/mysql/bin/mysql -uroot -p123456 -e "create database if not exists owncloud;grant all on owncloud.* to owncloud@'localhost' identified by 'owncloud'" &>/dev/null
}
#LAMP architecture and private cloud configuration
lamp(){
	gcc
	ls /etc/httpd/ &>/dev/null || apache
	ls /usr/local/mysql/bin &>/dev/null || mysql
	ls /usr/local/apache/modules|grep -w "libphp5.so" &>/dev/null || php
	owncloud
	main_menu
}
#Page main menu
main_menu(){
echo -e "Enter\033[31m1\033[0m Compile and install Apache..."
echo -e "Enter\033[32m2\033[0m Compile and install MySQL..."
echo -e "Enter\033[33m3\033[0m Compile and install PHP..."
echo -e "Enter\033[34m4\033[0m Configuring OWNCLOUD Private Cloud ..."
echo -e "Enter\033[35m5\033[0m One-click build LAMP architecture and complete private cloud configuration..."
echo -e "Enter\033[36m6\033[0m Exit this page..."
select choice in "apache install" "mysql install" "php install" owncloud LAMP exit;do
case $choice in
	"apache install")
		gcc && apache ;;
	"mysql install")
		gcc && mysql ;;
	"php install")
		php ;;
	LAMP)
		lamp ;;
	owncloud)
		owncloud ;;
	exit)
		exit ;;
esac
done
}
cat <<-EOF
########################################################################################
#   		Welcome to the owncloud private cloud installation system!             #
# 	Enter 1 to enter the system to automatically install the private cloud service!#
#           		Enter 2 to exit the system!                                    #
########################################################################################
EOF
read -p "Your choice is : " select
case $select in
	1)
		main_menu ;;
	2)
		exit ;;
esac
