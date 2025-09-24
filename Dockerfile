# Use the base PHP-Apache image
FROM devopsedu/webapp

# Copy your PHP application code into the web root
COPY . /var/www/html/

# Expose Apache port
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
