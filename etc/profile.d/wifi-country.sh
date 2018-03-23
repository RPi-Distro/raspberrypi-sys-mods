(
	export TEXTDOMAIN=wifi-country

	if [ -x /usr/bin/gettext.sh ]; then
		. /usr/bin/gettext.sh
	fi

	if [ ! -f /run/wifi-country-unset ]; then
		exit 0
	fi

	if ! /bin/grep -q '^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[dD][0-9a-fA-F]$' /proc/cpuinfo ; then
		exit 0
	fi

	if /sbin/iw reg get | /bin/grep -q "country [A-Z][A-Z]:" ; then
		exit 0
	fi

	echo
	if [ -x /usr/bin/gettext ]; then
		/usr/bin/gettext -s "Wi-Fi is disabled because the country is not set."
		/usr/bin/gettext -s "Use raspi-config to set the country before use."
	fi
	echo
)
