# Server prep: okaze-www2 configuration.
# Do not invoke directly, use ./prepare-server in the parent directory.

datadir="$1"
workdir="$2"

# Install software specifically for this host.
PACKAGES="docker.io docker-compose nginx-full"
PACKAGES="$PACKAGES certbot python3-certbot-nginx"
apt-get -y install $PACKAGES

# nginx configuration
(
    # None of the modules activated by default in nginx-full are
    # useful to us.
    cd /etc/nginx/modules-enabled
    rm *.conf

    # Across-the-board configuration overrides
    cd /etc/nginx
    sed -i.orig -e '
        /ssl_protocols /s//# &/
        /ssl_prefer_server_ciphers/ s//# &/
        /access_log /s//# &/
        /error_log /s//# &/
        /gzip /s//# &/
    ' nginx.conf

    cd /etc/nginx/conf.d
    cp "$datadir"/nginx-local.conf 99_local.conf

    # Disable the default vhost and enable the www2 and www3 vhosts.
    cd /etc/nginx/sites-available
    cp "$datadir"/www2.conf www2
    cp "$datadir"/www3.conf www3

    cd /etc/nginx/sites-enabled
    rm *
    ln -s ../sites-available/www2 .
    ln -s ../sites-available/www3 .

    cd /etc/letsencrypt
    cp "$datadir"/ocsp_chain.pem ocsp_chain.pem

    # Test configuration file syntax
    nginx -t
)

# A few files are served out of the standard webroot.
(
    cd /var/www/html
    rm *
    cp "$datadir"/favicon.ico .
    cp "$datadir"/robots.txt .
    mkdir -p .well-known/acme-challenge
)

# Restart nginx and open up the HTTP port on the firewall.
# At this point nginx will only serve unencrypted HTTP.
systemctl stop nginx.service
ufw allow http
systemctl start nginx.service

# Acquire TLS certificates from Let's Encrypt.  This requires the web
# server to be running (unencrypted only) to perform an ACME handshake.
certbot certonly -n --webroot \
        -w /var/www/html -d www2.okoze.net,www3.okoze.net \
        -m zackw@cmu.edu --agree-tos --no-eff-email

# Enable TLS in the vhosts, open the HTTPS port and restart nginx again.
(
    cd /etc/nginx/sites-available
    sed -i.notls -e 's/#TLS#/     /g' www2 www3
)
systemctl stop nginx.service
ufw allow https
systemctl start nginx.service
