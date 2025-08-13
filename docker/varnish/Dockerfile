FROM varnish:7.2-alpine

# Copy the Varnish configuration
COPY default.vcl /etc/varnish/default.vcl

# Expose port 80
EXPOSE 80

# Set the default command
CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl", "-s", "malloc,2G", "-a", "0.0.0.0:80"]
