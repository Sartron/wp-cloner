# wp-cloner
Bash script that will clone the current Wordpress installation into a new one. This is primarily useful to see if any core Wordpress files are messed up.

## Usage
`bash <(curl -s https://raw.githubusercontent.com/Sartron/wp-cloner/master/wpcloner.sh)`  
This script should be executed within the directory where Wordpress is installed.

## Example

```
[root@server ~]# cd /home/username/public_html
[root@server public_html]# bash <(curl -s https://raw.githubusercontent.com/Sartron/wp-cloner/master/wpcloner.sh)
You are running this in /home/username/public_html. Press enter to proceed, or Ctrl+C to cancel!
Downloading Wordpress 4.8.4: Exists
Extracting Wordpress: Done
Configuring URL: Done
Correcting permissions: Done

New Wordpress installation created!
 Directory: /home/username/public_html/wpcloner_wp16887
 Site URL: https://domain.tld/wpcloner_wp16887
 Home URL: https://domain.tld/wpcloner_wp16887
```