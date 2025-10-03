# Use official PHP + Apache image
FROM php:7.4-apache

# Copy website files into container's web root
COPY . /var/www/html/

# Give Apache permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose Apache port
EXPOSE 80
