#!/bin/bash

find /var/www -maxdepth 1 -mindepth 1 -type d -name 'web[0-9]*' | while read line; do
	if [ -d "${line}/web" ]; then
		siteNameDir="$(ls -l /var/www/ | grep -w "${line}" | tail -n 1 | egrep -o '(www.*)')"
		if [[ "${siteNameDir}" =~ "cgp" ]]; then
			donothing=''
		elif [ -d "${line}/web/typo3conf" ]; then
			frameWork="TYPO3     "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/sites/default/settings.php" ] || [ -d "${line}/web/sites/default/files" ]; then
			frameWork="Drupal    "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/wp-config.php" ]; then
			frameWork="WordPress "
			echo "${frameWork} ${siteNameDir}"
		elif [ -d "${line}/web/libraries/joomla" ]; then
			frameWork="Joomla    "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/app/Mage.php" ]; then
			frameWork="Magento   "
			echo "${frameWork} ${siteNameDir}"
		elif [ -d "${line}/web/moodledata" ]; then
			frameWork="Moodle    "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/core/lib/cls_ft.php" ] || [ -f "${line}/web/lib/cls_ft.php" ]; then
			frameWork="Kernelic  "
			echo "${frameWork} ${siteNameDir}"
		elif [ -d "${line}/web/cake" ]; then
			frameWork="CakePHP   "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/module/api/include/phpfox.class.php" ]; then
			frameWork="PHPFox    "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/images/mantis_logo.gif" ]; then
			frameWork="Mantis    "
			echo "${frameWork} ${siteNameDir}"
		elif [ -f "${line}/web/system/core/CodeIgniter.php" ]; then
			frameWork="CodeIgn   "
			echo "${frameWork} ${siteNameDir}"
		elif [ -d "${line}/web/services/Core/Amf" ]; then
			frameWork="AmfPHP    "
			echo "${frameWork} ${siteNameDir}"
		else
			filesInDocroot=`find "${line}/web" -maxdepth 1 -type f | wc -l`
			if [[ "$filesInDocroot" = "1" ]]; then
				echo "EMPTY!!!   -------------- ${siteNameDir}"
			else
				otherDocRoots=$(find "${line}/web" -type d -name typo3conf;\
				find "${line}/web" -type f -path '*sites/default/settings.php';\
				find "${line}/web" -type f -path '*wp-includes/wp-db.php';\
				find "${line}/web" -type d -path '*libraries/joomla';\
				find "${line}/web" -type f -path '*app/Mage.php';)
				if [ -z "$otherDocRoots" ]; then
						frameWork="Unknown!!!"
						echo "${frameWork} ${siteNameDir}"
				else
						echo "OTHER      ${siteNameDir}"
						echo "$otherDocRoots";
				fi
			fi
		fi

		#find "${line}/web" -type d -iname 'phpmyadmin'
	fi
done

