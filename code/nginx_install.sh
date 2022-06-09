#!/usr/bin/env bash
#
# Name: nginx_install.sh
# Desc: Nginx online source code compilation and installation script.
# Path: https://www.liruiyi.xyz/code/nginx_install.sh
# Usage: ./nginx_insell.sh --help
# Update: 2022-04-28 10:26:30

NGINX_VERSION=${NGINX_VERSION:-'1.20.1'}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-'/usr/local/src'}
INSTALL_PATH=${INSTALL_PATH:-'/usr/local/nginx'}
NGINX_USER=${NGINX_USER:-'nginx'}
NGINX_DEPEND=${NGINX_DEPEND:-'gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel'}
NGINX_DOWN_URL=${NGINX_DOWN_URL:-"http://nginx.org/download/nginx-"${NGINX_VERSION}".tar.gz"}

COMPILE_OPTIONS="--prefix=$INSTALL_PATH \
--user=$NGINX_USER --group=$NGINX_USER \
--conf-path=$INSTALL_PATH/conf/nginx.conf \
--pid-path=$INSTALL_PATH/logs/nginx.pid \
--http-log-path=$INSTALL_PATH/logs/access.log \
--error-log-path=$INSTALL_PATH/logs/error.log \
--http-client-body-temp-path=/var/tmp/client \
--http-fastcgi-temp-path=/var/tmp/fastcgi \
--http-proxy-temp-path=/var/tmp/proxy \
--http-scgi-temp-path=/var/tmp/scgi \
--http-uwsgi-temp-path=/var/tmp/uwsgi \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_gzip_static_module"

RED=$(tput setaf 1)         # ('\033[31m')
GREEN=$(tput setaf 2)       # ('\033[32m')
YELLOW=$(tput setaf 3)      # ('\033[33m')
RESET=$(tput sgr0)          # ('\033[00m')

log::error () {
    printf "${RED}[ERROR]${RESET} %b\n" "$@" 
}
log::warning () {
    printf "${YELLOW}[WARNGIN]${RESET} %b\n" "$@"
}
log::info () {
    printf "${GREEN}[INFO]${RESET} %b\n" "$@"
}

check_if_running_as_root () 
{
    if [[ "$UID" -ne '0' ]]; then
        log::warning "The user currently executing this script is not root."
        read -r -p "Are you sure you want to continue? [y/n] " enter_information
        if [[ "${enter_information:0:1}" = 'y' ]]; then
            log::info "Continuing the installation with current user..."
        else
            log::info "Not running with root, exiting..."
            exit 1
        fi
    fi
}

print_variables ()
{
    log::info "Use the command \"export variable=value\" change variable."
    echo
    echo NGINX_VERSION=\""${NGINX_VERSION}"\"
    echo DOWNLOAD_DIR=\""${DOWNLOAD_DIR}"\"
    echo NGINX_USER=\""${NGINX_USER}"\"
    echo NGINX_DEPEND=\""${NGINX_DEPEND}"\"
    echo NGINX_DOWN_URL=\""${NGINX_DOWN_URL}"\"
    echo
}

print_help ()
{
    echo "Usage: $0 [OPTION]..."
    echo
    echo "  -f, --file[=FILE]      specify the file, the download step will be skipped"
    echo "  -v, --variable         display the variable values used when this script runs"
    echo "  -h, --help             display this help and exit"
    echo "      --remove           remove the nginx software and its services"
    echo "      --skip-depend      skip dependency installation at execution time"
    echo "      --skip-download    skip downloading the nginx installation package"
    echo
}

install_software ()
{
    PACKAGE_NAME=$1
    PACKAGE_MANAGEMENT_INSTALL="yum -y install"
    if ${PACKAGE_MANAGEMENT_INSTALL} "${PACKAGE_NAME}"; then
        log::info "${PACKAGE_NAME} is installed"
    else
        log::error "Installation of ${PACKAGE_NAME} failed, please check your network."
        exit 1
    fi
}

unzip_nginx () 
{
    if tar zxf "$1" -C "$DOWNLOAD_DIR"; then
        log::info "Unzip the Nginx installation file successfully"
        NGINX_FILE_PREPARATION='yes'
    else
        log::error "Unzipping Nginx installation files failed."
        exit 1
    fi
}

download_nginx ()
{
    NGINX_FILE="${DOWNLOAD_DIR}/nginx-${NGINX_VERSION}.tar.gz"
    if [[ "${NGINX_FILE_PREPARATION}" != 'yes' ]]; then
        if curl -o "${NGINX_FILE}" http://nginx.org/download/nginx-"${NGINX_VERSION}".tar.gz; then
            log::info "Download nginx-${NGINX_VERSION}.tar.gz successfully."
            unzip_nginx "${NGINX_FILE}"
        else
            log::error "Download nginx-${NGINX_VERSION}.tar.gz failed."
            exit 1
        fi
    fi
}

create_nginx_user ()
{
    USER=$1
    if id "$1" &> /dev/null; then
        log::warning "$1 user already exists."
    else
        useradd -s /sbin/nologin -M "$1"
        log::info "$1 user create successful."
    fi
}

install_nginx ()
{
    cd "${DOWNLOAD_DIR}/nginx-$NGINX_VERSION" || exit 1
    if ./configure ${COMPILE_OPTIONS}; then
        log::info "Configure Nginx-${NGINX_VERSION} successful."

        if make;then
            log::info "Make Nginx-${NGINX_VERSION} successful."

            if make install;then
                log::info "Make Install Nginx-${NGINX_VERSION} successful."
            else
                log::error "Make Install Nginx-${NGINX_VERSION}  failed."
                exit 1
            fi

        else
            log::warning "Make Nginx-${NGINX_VERSION}  failed."
            exit 1
        fi

    else
        log::error "Configure Nginx-${NGINX_VERSION} failed."
        exit 1
    fi
}

install_service ()
{
cat <<EOF | tee /etc/systemd/system/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=$INSTALL_PATH/logs/nginx.pid
ExecStartPre=$INSTALL_PATH/sbin/nginx -t -c $INSTALL_PATH/conf/nginx.conf
ExecStart=$INSTALL_PATH/sbin/nginx -c $INSTALL_PATH/conf/nginx.conf
ExecReload=$INSTALL_PATH/sbin/nginx -s reload
ExecStop=$INSTALL_PATH/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

chmod +x /usr/lib/systemd/system/nginx.service
systemctl daemon-reload
log::info "Create nginx service file."

}

remove_nginx ()
{
    log::error "This option is not available..."
}

script_parameters ()
{
    while [[ "$#" -gt '0' ]]; do
        case "$1" in
            '-h' | '--help')
                print_help
                exit 0
            ;;
            '-v' | '--variable')
                print_variables
                exit 0
            ;;
            '--remove')
                remove_nginx
                exit 0
            ;;
            '-f' | '--file' | '--file'*)
                if [[ "$1" = '-f' || "$1" = '--file' ]] ; then
                    [[ -z "$2" ]] && log::error 'FILE=? File not specified' && exit 1
                    [[ ! -f "$2" ]] && log::error 'FILE=? File not specified' && exit 1
                    unzip_nginx "$2"
                    shift
                elif [[ "$1" =~ --file=([^ ].*) ]]; then
                    [[ ! -f "${BASH_REMATCH[1]}" ]] && log::error 'FILE=? File not specified' && exit 1
                    unzip_nginx "${BASH_REMATCH[1]}"
                else
                    log::error 'FILE=? File not specified'
                    exit 1
                fi
            ;;
            '--skip-depend')
                SKIP_DEPEND='yes'
            ;;
            '--skip-download')
                NGINX_FILE_PREPARATION='yes'
            ;;
            *)
                log::error "$1 invalid parameter"
                print_help
                exit 1
            ;;
        esac
        shift
    done
}

main () 
{
    check_if_running_as_root
    script_parameters "$@"

    if [[ "${SKIP_DEPEND}" != 'yes' ]]; then
        read -r -a DEPEND <<< "${NGINX_DEPEND}"
        DEPEND=($NGINX_DEPEND)
        for i in "${DEPEND[@]}";do
            install_software "$i"
        done
    fi

    download_nginx
    create_nginx_user ${NGINX_USER}
    install_nginx
    install_service
    ln -s $INSTALL_PATH/sbin/nginx /usr/local/sbin/
    ln -s /usr/local/nginx/conf/ /etc/nginx
    log::info "Install Nginx-${NGINX_VERSION} successful."

}
main "$@"