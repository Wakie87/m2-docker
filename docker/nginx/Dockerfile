FROM nginx:1.25-alpine

# Copy the nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
