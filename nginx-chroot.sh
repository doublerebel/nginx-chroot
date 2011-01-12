##
## Chrooting nginx for Ubuntu 10.04 LTS (Lucid)
## by Charles Phillips <charles@doublerebel.com>
## Jan 2011
##
## Tested on Ubuntu 10.04 Minimal
##
## Based on:
## http://www.cyberciti.biz/faq/howto-run-nginx-in-a-chroot-jail/
##
## MIT Licensed, Use at your own risk
##
##

NGINX_JAIL=/home/nginx
INSTALL_FILES=/home/installer/install_files


echo "Creating chroot jail for nginx..."

mkdir -p ${NGINX_JAIL}

echo "Creating nginx user..."
# http://www.cyberciti.biz/faq/rhel-linux-install-nginx-as-reverse-proxy-load-balancer/
useradd -s /usr/sbin/nologin -d ${NGINX_JAIL} -M nginx
# lock the account
passwd -l nginx

# Step #2: Create Isolated Environment
echo "Creating basic filesystem structure..."
mkdir -p ${NGINX_JAIL}/{etc,etc/nginx,dev,var,var/log,var/log/nginx,/var/lib,/var/lib/nginx,var/run,usr,usr/sbin,tmp,var/tmp,lib64,home,home/nginx}
chmod 1777 ${NGINX_JAIL}/tmp
chmod 1777 ${NGINX_JAIL}/var/tmp

# Step #3: Create Required Devices in ${NGINX_JAIL}/dev
echo "Creating required devices..."
cd ${NGINX_JAIL}
ls -l /dev/{null,random,urandom}
/bin/mknod -m 0666 ${NGINX_JAIL}/dev/null c 1 3
/bin/mknod -m 0666 ${NGINX_JAIL}/dev/random c 1 8
/bin/mknod -m 0444 ${NGINX_JAIL}/dev/urandom c 1 9

# Step #4: Copy All Nginx Files In Directory
echo "Copying nginx files..."
/bin/cp -farv /etc/nginx/* ${NGINX_JAIL}/etc/nginx
/bin/cp /usr/sbin/nginx ${NGINX_JAIL}/usr/sbin/

# Step #5: Copy Required Libs To Jail
# Uses n2chroot from http://bash.cyberciti.biz/web-server/nginx-chroot-helper-bash-shell-script/
# n2chroot must be edited to set BASE directory! Would prefer to pass ${NGINX_JAIL} parameter
echo "Copying libs..."
chmod +x ${INSTALL_FILES}/n2chroot
${INSTALL_FILES}/n2chroot /usr/sbin/nginx
/bin/cp -fv /lib64/* ${NGINX_JAIL}/lib64

# apparently, n2chroot misses these two libs:
/bin/cp -fv /lib/{libnss_compat.so.2,libnsl.so.1,libnss_nis.so.2,libnss_files.so.2} ${NGINX_JAIL}/lib
# if you are still missing libs, you can strace chrooted nginx as described here:
# http://forum.nginx.org/read.php?2,163489,163540#msg-163540

echo "Fixing init script for chroot..."
/bin/cp /etc/init.d/nginx /etc/init.d/nginx.prechroot
/bin/cp ${INSTALL_FILES}/nginx /etc/init.d/nginx
chmod 0755 /etc/init.d/nginx

# Step #6: Copy /etc To Jail, And a few directories too:
echo "Copying etc..."
cp -fv /etc/{group,prelink.cache,services,adjtime,shells,gshadow,shadow,hosts.deny,localtime,nsswitch.conf,nscd.conf,prelink.conf,protocols,hosts,passwd,ld.so.cache,ld.so.conf,resolv.conf,host.conf} ${NGINX_JAIL}/etc
cp -avr /etc/{ld.so.conf.d,prelink.conf.d} ${NGINX_JAIL}/etc

# If using SSL, /usr/lib/ssl and /usr/lib/ssl/* will also need to be added to jail

echo "Copying nginx.conf to nginx jail to run as nginx user..."
mv /home/installer/install_files/nginx.conf ${NGINX_JAIL}/etc/nginx
chmod 644 ${NGINX_JAIL}/etc/nginx/nginx.conf

chown nginx:nginx /home/nginx/home/nginx

echo "Killing nginx..."
killall -9 nginx
echo "Starting chrooted nginx..."
/usr/sbin/chroot /home/nginx /usr/sbin/nginx -t
/usr/sbin/chroot /home/nginx /usr/sbin/nginx

echo "Adding chrooted nginx to startup in /etc/rc.local..."
echo '/usr/sbin/chroot ${NGINX_JAIL} /usr/sbin/nginx' >> /etc/rc.local

echo "Finished installing apps."
echo ""
exit 0
