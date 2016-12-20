check_hash ()
{
   if ! id -u pi > /dev/null 2>&1 ; then return 0 ; fi
   if grep -q "^PasswordAuthentication\s*no" /etc/ssh/sshd_config ; then return 0 ; fi
   test -x /usr/bin/mkpasswd || return 0
   SHADOW="$(sudo -n grep -E '^pi:' /etc/shadow 2>/dev/null)"
   test -n "${SHADOW}" || return 0
   if echo $SHADOW | grep -q "pi:!" ; then return 0 ; fi
   SALT=$(echo "${SHADOW}" | sed -n 's/pi:\$6\$//;s/\$.*//p')
   HASH=$(mkpasswd -msha-512 raspberry "$SALT")
   test -n "${HASH}" || return 0

   if echo "${SHADOW}" | grep -q "${HASH}"; then
		echo
		echo "SSH is enabled and the default password for the 'pi' user has not been changed."
		echo "This is a security risk - please login as the 'pi' user and type 'passwd' to set a new password."
		echo
   fi
}

if service ssh status | grep -q running; then
	check_hash
fi
unset check_hash
