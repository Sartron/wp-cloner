#!/bin/bash

# Static Variables
readonly USER=$(stat -c'%U' .);
readonly VERSION='1.00';
readonly UPDATED='August 13 2017'

# Script Variables
SITEURL='';
HOMEURL='';

function DirIsWP()
{
	# Check for these core files and for the wp-content folder.
	[ ! -f "${1}/wp-config.php" ] && { echo "Error: ${1}/wp-config.php not found!"; return 1; };
	[ ! -f "${1}/wp-includes/version.php" ] && { echo "Error: ${1}/wp-includes/version.php not found!"; return 1; };
	[ ! -d "${1}/wp-content" ] && { echo "Error: ${1}/wp-content not found!"; return 1; };
	
	# No errors were encountered. Proceed with the script.
	return 0;
}

function CreateHtaccess()
{
	# Create the new .htaccess file with new site URL and base URL.
	echo "
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /${1}/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /${1}/index.php [L]
</IfModule>

# END WordPress" > "${1}/.htaccess";
}

function SetupWPConfig()
{
	# Get all database variables.
	local wpdb=$(grep 'DB_NAME' ./wp-config.php | cut -d"'" -f4);
	local wpuser=$(grep 'DB_USER' ./wp-config.php | cut -d"'" -f4);
	local wppass=$(grep 'DB_PASSWORD' ./wp-config.php | cut -d"'" -f4);
	local wpprefix=$(grep 'table_prefix' ./wp-config.php | cut -d"'" -f2)
	
	# Try and connect to the local MySQL server using these details.
	SITEURL=$(mysql -u ${wpuser} -p''${wppass}'' -D ${wpdb} -e "SELECT option_value FROM "${wpprefix}options" WHERE option_name = 'siteurl'" -r -ss 2> /dev/null);
	HOMEURL=$(mysql -u ${wpuser} -p''${wppass}'' -D ${wpdb} -e "SELECT option_value FROM "${wpprefix}options" WHERE option_name = 'home'" -r -ss 2> /dev/null);
	
	# If either the site URL or home URL is not returned, script fails.
	[[ -z ${SITEURL} || -z ${HOMEURL} ]] && { echo 'Database connection may have failed, or Site URL/Home URL variables don''t exist!'; return 1; };
	
	# Add a trailing slash to the site URL and home URL if needed.
	[ "$(tail -c'2' <<< "${SITEURL}")" == '/' ] || SITEURL+='/';
	[ "$(tail -c'2' <<< "${HOMEURL}")" == '/' ] || HOMEURL+='/';
	
	# Add new URLs to wp-config.php.
	sed -i "s|\/\* That's all|define('WP_HOME','${HOMEURL}${wpdirname}');\ndefine('WP_SITEURL','${SITEURL}${wpdirname}');\n/* That's all|g" "${wpdirname}/wp-config.php";
}

function RemoveWP()
{
	echo -e 'Failed\n';
	echo -n "Deleting ./${1}: ";
	rm -fr "${wpdirname}" && { echo 'Done'; exit 1; };
}

function Main()
{
	# Check if current directory has Wordpress installed.
	DirIsWP ${PWD} || return 1;
	
	# Get Wordpress version and generate a random directory name.
	local wpversion=$(grep 'wp_version =' ./wp-includes/version.php | cut -d \' -f2);
	local wpdirname="wpcloner_wp${RANDOM}";
	
	# Pre-checks
	# 1. Ensure randomized Wordpress directory doesn't exist.
	# 2. Ensure that a Wordpress version was returned.
	while [ -d "./${wpdirname}" ];
	do
		wpdirname="wpcloner_wp${RANDOM}";
	done
	[[ -z ${wpversion} ]] && echo 'Error: Wordpress version not found within ./wp-includes/version.php' && return 1;
	
	# Warning to back out before running script.
	read -p "You are running this in ${PWD}. Press enter to proceed, or Ctrl+C to cancel! " PLACEHOLDERVAR;
	[[ ${PLACEHOLDERVAR} == 'n' || ${PLACEHOLDERVAR} == 'N' ]] && return 0;
	
	# Download Wordpress.
	echo -n "Downloading Wordpress $wpversion: ";
	mkdir -p "${HOME}/wpcloner";
	if [ -f "${HOME}/wpcloner/wordpress-${wpversion}.tar.gz" ]; then
		echo 'Exists';
	else
		wget -q --no-check-certificate --directory-prefix="${HOME}/wpcloner" https://wordpress.org/wordpress-${wpversion}.tar.gz;
		[ "${?}" != '0' ] && { echo -e 'Failed\n\nError: Failed to download Wordpress!'; return 1; } || echo 'Done';
	fi
	
	# Extract archive within current Wordpress directory and rename it to wpcloner_wp.
	echo -n 'Extracting Wordpress: ';
	if [ -d wordpress ]; then
		echo -e 'Failed\n\nError: Directory ./wordpress already exists!';
		return 1;
	else
		tar zxf "${HOME}/wpcloner/wordpress-${wpversion}.tar.gz";
		[ -d "${wpdirname}" ] && return 1 || mv wordpress "${wpdirname}";
		echo 'Done'
	fi
	
	# Port over existing configuration to new installation.
	cp -f wp-config.php ${wpdirname}/;
	rm -fr ${wpdirname}/wp-content;
	ln -s ../wp-content ${wpdirname}/wp-content;
	chown -h ${USER}. ${wpdirname}/wp-content;
	
	# Customize new installation to use proper URL.
	echo -n 'Configuring URL: '
	CreateHtaccess ${wpdirname};
	SetupWPConfig || RemoveWP ${wpdirname};
	echo 'Done';
	
	# Correct permissions of new Wordpress installation.
	echo -n 'Correcting permissions: ';
	chown -R ${USER}. ${wpdirname};
	find ${wpdirname} -type f -exec chmod 644 {} \;;
	find ${wpdirname} -type d -exec chmod 755 {} \;;
	echo 'Done';
	
	# Done
	echo -e "\nNew Wordpress installation created!
 Directory: ${PWD}/${wpdirname}
 Site URL: ${SITEURL}${wpdirname}
 Home URL: ${HOMEURL}${wpdirname}";
}

Main "${@}" || exit 1;