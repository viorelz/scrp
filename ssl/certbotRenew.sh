#!/bin/bash

today=$(date +%H:%M:%S.%Y-%m-%d)
CUR_DIR=$(dirname "$0")
LOGFILE="$CUR_DIR/certbot_renew.log"
LOGEVALHTTP="$CUR_DIR/certbot_http.log"
LOGEVALNGINX="$CUR_DIR/certbot_nginx.log"
echo "$today" >> "$LOGFILE"

SERVICE_ACTIVE="active"
SERVICE_INACTIVE="inactive"
SERVICE_FAILED="failed"
SERVICE_UNKNOWN="unknown"

# check what web servers are running
STATUS_HTTPD=$(/usr/bin/systemctl is-active httpd.service)
STATUS_APACHE=$(/usr/bin/systemctl is-active apache.service)
STATUS_NGINX=$(/usr/bin/systemctl is-active nginx.service)
STATUS_POSTFIX=$(/usr/bin/systemctl is-active postfix.service)
STATUS_DOVECOT=$(/usr/bin/systemctl is-active dovecot.service)

httpd_condition="Syntax OK"
apache_condition="Syntax OK"
nginx_condition="test is successful"
certbot_condition="Congratulations, all renewals succeeded. The following certs have been renewed:"

# Check if HTTPD config is OK
if [ "$STATUS_HTTPD" == "$SERVICE_ACTIVE" ] || [ "$STATUS_APACHE" == "$SERVICE_ACTIVE" ]; then
    /usr/sbin/apachectl -t > "$LOGEVALHTTP" 2>&1
    s=$(grep "$apache_condition" "$LOGEVALHTTP")
    httpd_success=$?
    if [ "$httpd_success" -ne 0 ]; then
        echo "HTTPD config NOT OK" >> "$LOGFILE"
        exit 1
    else
        echo "HTTPD config is OK" >> "$LOGFILE"
    fi
fi
# Check if Nginx config is OK
if [ "$STATUS_NGINX" == "$SERVICE_ACTIVE" ]; then
    /usr/sbin/nginx -t > "$LOGEVALNGINX" 2>&1
    s=$(grep "$nginx_condition" "$LOGEVALNGINX")
    nginx_success=$?
    if [ "$nginx_success" -ne 0 ]; then
        echo "Nginx config NOT OK" >> "$LOGFILE"
        exit 1
    else
        echo "Nginx config is OK" >> "$LOGFILE"
    fi
fi

# stop the web server(s)
if [ "$STATUS_HTTPD" == "$SERVICE_ACTIVE" ] || [ "$STATUS_APACHE" == "$SERVICE_ACTIVE" ]; then
    /usr/bin/systemctl stop httpd.service
fi
if [ "$STATUS_NGINX" == "$SERVICE_ACTIVE" ]; then
    /usr/bin/systemctl stop nginx.service
fi

# do the renew
sleep 1
/usr/bin/certbot --standalone renew > "$LOGFILE" 2>&1
sleep 5

# restart the services
STATUS_HTTPD=$(/usr/bin/systemctl is-active httpd)
if [ "$STATUS_HTTPD" != "$SERVICE_ACTIVE" ]; then
    /usr/bin/systemctl start httpd.service
fi
STATUS_APACHE=$(/usr/bin/systemctl is-active apache)
if [ "$STATUS_APACHE" != "$SERVICE_ACTIVE" ]; then
    /usr/bin/systemctl start apache.service
fi
STATUS_NGINX=$(/usr/bin/systemctl is-active nginx)
if [ "$STATUS_NGINX" != "$SERVICE_ACTIVE" ]; then
    /usr/bin/systemctl start nginx.service
fi

#Check that renew was successfull
certbot_success=$(grep "Congratulations, all renewals succeeded. The following certs have been renewed:" "$LOGFILE")
if [ "$certbot_success" == "$certbot_condition" ]; then
    STATUS_HTTPD=$(/usr/bin/systemctl is-active httpd)
    if [ "$STATUS_HTTPD" == "$SERVICE_ACTIVE" ]; then
        echo "HTTPD is alive after renew" >> "$LOGFILE"
    else
        echo "HTTPD didn't make it after renew" >> "$LOGFILE"
    fi
    STATUS_APACHE=$(/usr/bin/systemctl is-active apache)
    if [ "$STATUS_APACHE" == "$SERVICE_ACTIVE" ]; then
        echo "APACHE is alive after renew" >> "$LOGFILE"
    else
        echo "APACHE didn't make it after renew" >> "$LOGFILE"
    fi
    STATUS_NGINX=$(/usr/bin/systemctl is-active nginx)
    if [ "$STATUS_NGINX" == "$SERVICE_ACTIVE" ]; then
        echo "NGINX is alive after renew" >> "$LOGFILE"
    else
        echo "NGINX didn't make it after renew" >> "$LOGFILE"
    fi
    if [ "$STATUS_POSTFIX" == "$SERVICE_ACTIVE" ]; then
        /usr/bin/systemctl restart postfix.service
    fi
    if [ "$STATUS_DOVECOT" == "$SERVICE_ACTIVE" ]; then
        /usr/bin/systemctl restart dovecot.service
    fi
else
    echo "certbot renewal NOT OK" >> "$LOGFILE"
fi
