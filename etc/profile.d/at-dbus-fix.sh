if ! /usr/bin/dpkg -l at-spi2-core | /bin/grep ii ; then
   export NO_AT_BRIDGE=1
fi
