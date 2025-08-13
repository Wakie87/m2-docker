FROM varnish:7.2-alpine

# Copy the Varnish configuration
COPY default.vcl /etc/varnish/default.vcl

# Create a simple health check script
RUN echo '#!/bin/sh\nvarnishstat -1 > /dev/null' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Expose port 80
EXPOSE 80

# Set the default command
CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl", "-s", "malloc,2G", "-a", "0.0.0.0:80"]
