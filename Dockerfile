FROM debian:buster-slim

ARG myinstall="install --no-install-recommends"

#Update and reduce image size
RUN apt update \
    && apt $myinstall -y \
    && apt $myinstall apt-utils -y \
    && apt $myinstall cron -y \
    && apt install git -y \
    && apt install curl -y \
    && apt $myinstall sudo -y

#add the pi user
RUN useradd -ms /bin/bash pi 
WORKDIR /home/pi
# Lighttpd & PHP
RUN apt $myinstall lighttpd -y \
    && mv /var/www/html/index.lighttpd.html /var/www/html/index.lighttpd.html.old \
    && ln -s ~/pialert/install/index.html /var/www/html/index.html \
    && apt $myinstall php php-cgi php-fpm php-sqlite3 -y \
    && lighttpd-enable-mod fastcgi-php \
    && apt $myinstall sqlite3 -y

# arp-scan, Python, ip tools
RUN apt install arp-scan -y \
    && apt $myinstall dnsutils net-tools -y \
    && apt $myinstall python -y \
    && apt $myinstall iproute2 -y

# Pi.Alert
RUN apt clean \
    && git clone https://github.com/iAmSaugata/Pi.Alert.git pialert     \ 
    # delete .git specific files to make the image smaller
    && rm -r /home/pi/pialert/.git \
    && ln -s /home/pi/pialert/front /var/www/html/pialert  \
    && python /home/pi/pialert/back/pialert.py update_vendors \    
    && (crontab -l 2>/dev/null; cat /home/pi/pialert/install/pialert.cron) | crontab - \
    && chgrp -R www-data /home/pi/pialert/db \
    && chmod -R 770 /home/pi/pialert/db \
    # changing the default port number 80 to something random, here 20211
    && sed -ie 's/= 80/= 20211/g' /etc/lighttpd/lighttpd.conf \
    && service lighttpd restart 

# Expose the below port
EXPOSE 20211

# Set up startup script to run two commands, cron and the lighttpd server
ADD start.sh /home/pi
RUN chmod +x /home/pi/start.sh

CMD ["/home/pi/start.sh"]
