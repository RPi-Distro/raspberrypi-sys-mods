if [ -f /run/systemd/generator/packagekit.service.d/dpkg-limit.conf ]; then
  export DPKG_DEB_THREADS_MAX=1
fi
