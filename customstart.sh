# this script (customstart.sh) is SOURCED by docker-entrypoint.sh

# This script is run whenever the container launches (eg "docker run" or
# "docker-compose up -d"). This script does not run if the container is
# restarted (eg "docker restart" or "docker-compose restart").

# The purpose of this script is to let you customise your Domoticz
# container by adding packages using "apt-get" or "pip3 install". This
# script runs as root so you do not have to use "sudo".

# If you make a mistake, delete this file, restart the container and
# the default version will be restored automatically.

# Example commands below. Uncomment commands to make then active and
# then edit the commands to meet your needs

#echo "updating packages list"
#apt-get -qq update

#echo "installing packages"
#apt-get -y install mosquitto-clients iputils-ping

#echo "installing Python packages"
#pip3 install aiohttp

