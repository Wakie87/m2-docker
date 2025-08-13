FROM varnish:7.2-alpine

# Install additional tools for healthchecks and debugging
RUN apk add --no-cache \
    curl \
    vim \
    && rm -rf /var/cache/apk/*

# Copy the Varnish configuration
COPY default.vcl /etc/varnish/default.vcl

# Create a health check script
RUN echo '#!/bin/sh\nvarnishstat -1 > /dev/null' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Expose port 80
EXPOSE 80

# Set the default command
CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl", "-s", "malloc,2G", "-a", "0.0.0.0:80"]
