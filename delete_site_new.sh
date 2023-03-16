#!/bin/bash

BOLD="\e[1m"
REVERSE="\e[7m"
RESET="\e[0m"

DEFF="\e[39m"
GREENF="\e[32m"
YELLOWF="\e[33m"
BLUEF="\e[34m"
DEFB="\e[49m"
REDB="\e[41m"
BLUEB="\e[44m"
GREENB="\e[42m"
NOCOLOR="\033[0m"

WORK_DIR="/root/tempo"
TMP_FILE="/tmp/delete_sites.txt"

# check if dialog utiliy is installed
which dialog > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo -e "${REDB}dialog utility is not present. Installing...${NOCOLOR}"
   yum install dialog -y
fi
# console size
COLS=$(tput cols)
LINES=$(tput lines)
# check if web server is Apache or Nginx
if [ -d /etc/nginx ] && [ -d /etc/httpd ]; then
  WS=$(dialog --title "Choose the victim" --menu "Pick a Web Server" $LINES $COLS $(( $LINES - 8 )) "httpd" "Apache" "nginx" "Nginx" --output-fd 1)
  RET_VAL=$?
  if [ $RET_VAL -ne 0 ]; then
    echo -e "${REVERSE}Bye, Bye..${RESET}"
    exit 1
  fi
elif [ -d /etc/httpd ]; then
  WS="httpd"
elif [ -d /etc/nginx ]; then
  WS="nginx"
fi
clear
# set folder for virtual host files
VHOSTS_DIR="/etc/$WS/vhosts.d"
# get a list of vhost files
FILES=$(find $VHOSTS_DIR -type f -name '*.conf' -printf "%f %TY-%Tm-%Td\n" | sort)

FILE=""
VHOST_FILES=""
DOM=""
DOMAIN=""
DOMAIN_NAME=""
VHOST_FILE=""
DOC_ROOT=""
DB_NAME=""
DB_USER=""
CRON_FILE=""
WEB_DIR=""

case "$WS" in
  httpd)
    # select the virtual host file
    VHOST_FILES=$FILES
    echo $VHOST_FILES
    FILE=$(dialog --title "Choose your victim" --menu "Pick a Vhost File" $LINES $COLS $(( $LINES - 8 )) $VHOST_FILES --output-fd 1)
    RET_VAL=$?
    if [ $RET_VAL -ne 0 ]; then
        echo -e "${REVERSE}Bye, Bye..${RESET}"
        exit 1
    fi
    read -p "You selected $FILE. Ok? [y/n]: " -n 1 REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${REVERSE}Bye, Bye..${RESET}"
        exit 1
    fi
    WEB_DIR="/var/www"
    ;;
  nginx)
    echo $FILES > $TMP_FILE
    # select the virtual host file
    # get only the virtual host files that match a user name
    for FILE in $FILES; do
      dom=$(echo $FILE | cut -d'.' -f 1)
      grep -wq $dom /etc/passwd
      RET_VAL=$?
      if [ $RET_VAL -ne 0 ]; then
        sed '/$dom/d' $TMP_FILE
      fi
    done
    VHOST_FILES=$(cat $TMP_FILE)
    echo $VHOST_FILES
    FILE=$(dialog --title "Choose your victim" --menu "Pick a Vhost File" $LINES $COLS $(( $LINES - 8 )) $VHOST_FILES --output-fd 1)
    RET_VAL=$?
    if [ $RET_VAL -ne 0 ]; then
        echo -e "${REVERSE}Bye, Bye..${RESET}"
        exit 1
    fi
    read -p "You selected $FILE. Ok? [y/n]: " -n 1 REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${REVERSE}Bye, Bye..${RESET}"
        exit 1
    fi
    WEB_DIR="/home"
    ;;
  *)
    echo "Unknown web server: $WS"
    exit
esac

DOM=$(basename $FILE)
DOMAIN=$(echo $DOM | cut -d'.' -f 1)
DOMAIN_NAME="${DOM%.*}"
VHOST_FILE="$VHOSTS_DIR/$FILE"
DOC_ROOT="$WEB_DIR/$DOMAIN_NAME"
DB_NAME="$DOMAIN"
DB_USER="$DOMAIN"u
CRON_FILE="/var/spool/cron/$DOMAIN"
HOME_DIR="/home/$DOMAIN"
TODAY=$(date +%Y.%m.%d)

clear
#########################################
### Create an archive with everything ###
#########################################
echo -e "${GREENB}Archiving important stuff${NOCOLOR}"
# create the working dir or
# clear it
if [ ! -d $WORK_DIR ]; then
    mkdir -p $WORK_DIR
#else
#    rm -fR "$WORK_DIR"/*
fi

# dump the database
echo "Dumping database $DB_NAME"
s=$(mysql -e "SELECT ROUND(SUM(data_length) * 0.8, 0) AS S FROM information_schema.TABLES WHERE table_schema LIKE '$DB_NAME'")
DB_SIZE=$(echo $s | cut -d' ' -f 2)
DB_FILE="${WORK_DIR}/${DB_NAME}_$TODAY".sql
echo "Dumping database $DB_NAME to $DB_FILE"
mysqldump --opt $DB_NAME | pv --progress > $DB_FILE
echo "Compressing dump..."
pv $DB_FILE | gzip > $DB_FILE.gz
rm -f $DB_FILE

# archive the database, code, home dir, vhost file and cron file
echo -e "${BOLD}Creating archive...${RESET}"
DB_SIZE=$(du -sb "$DB_FILE".gz | cut -f 1)
DOC_ROOT_SIZE=$(du -sb $DOC_ROOT | cut -f 1)
HOME_DIR_SIZE=$(du -sb $HOME_DIR | cut -f 1)
TOTAL_SIZE=$(( $DB_SIZE + $DOC_ROOT_SIZE + $HOME_DIR_SIZE ))

if [ -f "$CRON_FILE" ]; then
    tar -cf - "$DB_FILE".gz $DOC_ROOT $HOME_DIR $VHOST_FILE $CRON_FILE -P | pv --size $TOTAL_SIZE | gzip > "${WORK_DIR}/${DOMAIN_NAME}_$TODAY".tar.gz
else
    tar -cf - "$DB_FILE".gz $DOC_ROOT $HOME_DIR $VHOST_FILE -P | pv --size $TOTAL_SIZE | gzip > "${WORK_DIR}/${DOMAIN_NAME}_$TODAY".tar.gz
fi

echo -e "${GREENF}Backup finished. You may find it in $WORK_DIR ${NOCOLOR}"
echo

#################################
### Delete the hosted website ###
#################################
echo -e "${REDB}Starting deletion process for $DOMAIN_NAME.${NOCOLOR}"
read -p 'Ok? [y/n]: ' -n 1 REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${REVERSE}Bye, Bye..${RESET}"
    exit 1
fi
echo -e "${BLUEF}Ok, you asked for it...${NOCOLOR}"
echo -e "${BLUEF}You still have 5 seconds to change your mind${NOCOLOR}"
for i in $(seq 5); do
    echo -n '.'; sleep 1
done
echo
echo -e "${BLUEF}Ooops... Too late. Starting job now.${NOCOLOR}"
echo "Removing vhost file $VHOST_FILE"
rm -f $VHOST_FILE
case "$WS" in
  httpd)
    echo "Reloading Apache config"
    systemctl reload httpd.service
    ;;
  nginx)
    echo "Restarting Nginx server"
    systemctl restart nginx.service
    ;;
esac
echo "Removing database $DB_NAME"
mysql -e "DROP DATABASE $DB_NAME"
echo "Removing database user $DB_USER"
mysql -e "DROP USER '$DB_USER'@'localhost'"
echo "Removing document root..."
rm -fR $DOC_ROOT
echo "Removing htpasswd file"
rm -f ${WEB_DIR}.${DOMAIN_NAME}
echo "Removing system user"
# remove apache from user's group
gpasswd -d apache $DOMAIN
userdel --remove $DOMAIN
#groupdel $DOMAIN
echo "Removing cron file"
if [ -f $CRON_FILE ]; then
    rm -f $CRON_FILE
    systemctl restart crond.service
fi
case "$WS" in
  httpd)
    echo "Removing Apache log files"
    rm -f "/var/www/log/$DOMAIN_NAME"*
    ;;
  nginx)
    echo "Removing Nginx log files"
    rm -f "/var/log/nginx/$DOMAIN_NAME"*
    ;;
esac
rm -f $TMP_FILE
echo -e "${BLUEF}Done.${NOCOLOR}"
