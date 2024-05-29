# this script (customstart.sh) is SOURCED by docker-entrypoint.sh

# presence of this file implies the container is already configured
FIRSTRUN="/opt/domoticz/FIRSTRUN"

# perform additional configuration if required
if [ ! -f "$FIRSTRUN" ] ; then

	echo "updating packages list"
	apt-get -qq update

	echo "installing packages"
	apt-get -y install mosquitto-clients iputils-ping

fi

# mark/update the container as configured
touch "$FIRSTRUN"
