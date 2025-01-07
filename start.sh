#!/bin/ash
echo "DEBUG: ENABLE_SSL=${ENABLE_SSL}"



# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Function to print messages with colors
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${RESET}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${RESET}"
}

# Clean up temp directory
echo "⏳ Cleaning up temporary files..."
if rm -rf /home/container/tmp/*; then
    log_success "Temporary files removed successfully."
else
    log_error "Failed to remove temporary files."
    exit 1
fi

# Check and set DOMAIN
if [ -z "$DOMAIN" ]; then
    log_warning "DOMAIN variable is not set. Using default: webtest.matahost.eu"
    DOMAIN="webtest.matahost.eu"
else
    log_success "DOMAIN is set to: $DOMAIN"
fi

# Replace DOMAIN in Nginx config
if [ -f "/home/container/nginx/conf.d/default.conf" ]; then
echo "Replacing DOMAIN in Nginx configuration..."
sed -i "s|\\\${DOMAIN}|${DOMAIN}|g" /home/container/nginx/conf.d/default.conf
log_success "Replaced DOMAIN in /home/container/nginx/conf.d/default.conf"

else
    log_error "Nginx configuration file not found at /home/container/nginx/conf.d/default.conf"
    exit 1
fi



# Display updated Nginx config for debugging
echo "Updated Nginx configuration:"
cat /home/container/nginx/conf.d/default.conf

# Start PHP-FPM
echo "⏳ Starting PHP-FPM..."
if /usr/sbin/php-fpm8 --fpm-config /home/container/php-fpm/php-fpm.conf --daemonize; then
    log_success "PHP-FPM started successfully."
else
    log_error "Failed to start PHP-FPM."
    exit 1
fi

# Configure SSL if enabled
if [ "${ENABLE_SSL}" = "true" ]; then
    echo "⏳ Configuring SSL with Let's Encrypt..."
    
    # Debug výpis pro jistotu, že proměnné jsou správně nastavené
    echo "SSL_EMAIL: ${SSL_EMAIL}"
    echo "DOMAIN: ${DOMAIN}"
    
    # Spuštění Certbotu pro vytvoření certifikátu
    if certbot --nginx -n --agree-tos --email "${SSL_EMAIL}" -d "${DOMAIN}"; then
        echo "✅ SSL setup complete."
    else
        echo "❌ Failed to configure SSL with Certbot. Check logs for details."
        exit 1
    fi
    
    # Ověření, zda certifikáty byly vytvořeny
    if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" ]; then
        echo "✅ SSL certificates exist and are ready to use."
    else
        echo "❌ SSL certificates are missing! Certbot may have failed."
        exit 1
    fi
else
    echo "⚠️ SSL setup skipped. ENABLE_SSL is set to false."
fi


# Start Nginx
echo "⏳ Starting Nginx..."
if /usr/sbin/nginx -c /home/container/nginx/nginx.conf -p /home/container/; then
    log_success "Nginx started successfully."
else
    log_error "Failed to start Nginx."
    exit 1
fi

# Keep the container running (optional, depending on your container setup)
tail -f /dev/null
