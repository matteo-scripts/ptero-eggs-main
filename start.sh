#!/bin/ash
echo "DEBUG: DOMAIN=${DOMAIN}"

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
