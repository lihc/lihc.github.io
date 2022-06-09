#!/usr/bin/env bash

exit 1

PHP_VERSION=${PHP_VERSION:-"7.4.10"}
PHP_REAY=${REAY:-"wget gcc gcc-c++ libxml2-devel sqlite-devel openssl-devel curl-devel libpng-devel libicu-devel"}
PHP_PATH=${PHP_PATH:-"/usr/local/php"}
PHP_GROUP=${PHP_GROUP:-"www"}
PHP_USER=${PHP_USER:-"www"}
SOFT_PATH=${SOFT_PATH:-"/usr/local/src"}
CONF_OPTION=${CONF_OPTION:-"--prefix=${PHP_PATH} \
--with-config-file-path=${PHP_PATH}/etc \
--enable-fpm \
--with-fpm-group=${PHP_GROUP} \
--with-fpm-user=${PHP_USER} \
--enable-exif \
--enable-mbstring \
--with-curl \
--with-mysqli \
--with-openssl \
--with-sodium \
--with-zip \
--enable-bcmath \
--enable-gd \
--enable-intl \
--with-zlib "}

if [ "${PHP_PATH: -1}" = "/" ];then PHP_PATH=${PHP_PATH%?}; fi
if [ "${SOFT_PATH: -1}" = "/" ];then PHP_PATH=${SOFT_PATH%?}; fi

# 安装依赖环境
dependent_software() {
    for i in "$@";do
        if yum -y install "$i";then
            echo "${green}[INFO]${reset}: Success installed $1"
        else
            echo "${red}[ERROR]${reset}: Failed to install $1"
            exit 1
        fi
    done
    yum -y install https://rpms.remirepo.net/enterprise/7/remi/x86_64/oniguruma5php-6.9.7.1-1.el7.remi.x86_64.rpm
    yum -y install https://rpms.remirepo.net/enterprise/7/remi/x86_64/oniguruma5php-devel-6.9.7.1-1.el7.remi.x86_64.rpm
}


# 下载软件源码
download_php() {
    if wget -N -P $SOFT_PATH https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz;then
        echo "${green}[INFO]${reset}: php-${PHP_VERSION}.tar.gz success downloaded"
    else
        echo "${red}[ERROR]${reset}: php-${PHP_VERSION}.tar.gz download failed"
        exit 1
    fi
    tar zxf $SOFT_PATH/php-${PHP_VERSION}.tar.gz -C $SOFT_PATH
}

# 创建用户和组
create_user_group() {
    if grep -q "${PHP_GROUP}" /etc/group;then
        echo "${yellow}[INFO]${reset}: ${PHP_GROUP} group already exists."
    else
        groupadd "${PHP_GROUP}"
        echo "${green}[INFO]${reset}: ${PHP_GROUP} group has been created."
    fi
    if id -u "${PHP_USER}" >& /dev/null;then
        echo "${yellow}[INFO]${reset}: ${PHP_USER} user already exists."
    else
        useradd -r -g "${PHP_GROUP}" -s /bin/false "${PHP_USER}"
        echo "${green}[INFO]${reset}: ${PHP_USER} user has been created."
    fi
    sleep 0.5s
}

# 编译安装 PHP
install_php() {
    cd $SOFT_PATH/php-${PHP_VERSION} || exit
    if ./configure "${CONF_OPTION}";then
        echo "install OK"
    else
        echo "install NO"
        echo "${CONF_OPTION}"
        pwd
        echo "./configure ${CONF_OPTION}"
        exit 1
    fi
    if make;then
        echo "make YES"
    else
        echo "make NO"
        exit 1
    fi
    if make install;then
        echo "make install Yes"
    else
        echo "make install no"
        exit 1
    fi
}

main() {
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    reset=$(tput sgr0)

    dependent_software $PHP_REAY
    download_php
    create_user_group
    install_php

}
main


export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz


./configure --prefix=/usr/local/php \ # PHP 安装目录
--enable-exif \ # 启用 EXIF(来自图像的元数据)支持
--enable-fpm \ # 启用构建 fpm SAPI 可执行文件
--enable-mbstring \ # 启用多字节字符串支持
--with-config-file-path=/usr/local/php/etc \ # PHP 配置文件目录
--with-curl \  # 包括 cURL 支持
--with-fpm-group=www \ # 设置 php-fpm 运行组 (默认值: nobody)
--with-fpm-user=www \ # 设置 php-fpm 运行用户 (默认值: nobody)
--with-mysqli \ # 包括 MySQLi 支持
--with-openssl \ # 包括 OpenSSL 支持(需要 OpenSSL >= 1.0.1)
--with-sodium \ # 包括 sodium 支持
--with-zip \ # 包括 Zip read/write 支持

--enable-bcmath # 启用 bc 样式的精确数学函数
--enable-gd # 包括 GD 支持
--enable-intl # 启用国际化支持
--with-zlib # 包括 ZLIB 支持 (需要 zlib >= 1.2.0.4)




./configure --prefix=/usr/local/php \
--with-fpm-group=www \
--with-fpm-user=www \
--enable-fpm

cp php.ini-development /usr/local/php/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /usr/local/php/php.ini

cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

useradd -s /bin/nologin -M www
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
systemctl daemon-reload
systemctl enable php-fpm.service
systemctl start php-fpm.service

ln -s /usr/local/php/bin/* /usr/local/bin/
ln -s /usr/local/php/sbin/* /usr/local/sbin/