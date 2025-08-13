vcl 4.1;

import std;

# Default backend definition
backend default {
    .host = "nginx";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 90s;
    .between_bytes_timeout = 2s;
}

# ACL for purging
acl purge {
    "localhost";
    "127.0.0.1";
    "::1";
}

# Handle PURGE requests
sub vcl_recv {
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405, "Not allowed."));
        }
        return (purge);
    }

    # Remove port from Host header
    if (req.http.host ~ ":") {
        set req.http.host = regsub(req.http.host, ":[0-9]+", "");
    }

    # Normalize Accept-Encoding header
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # Don't cache admin, checkout, or customer areas
    if (req.url ~ "^/admin" || req.url ~ "^/checkout" || req.url ~ "^/customer" || req.url ~ "^/my-account") {
        return (pass);
    }

    # Don't cache POST requests
    if (req.method == "POST") {
        return (pass);
    }

    # Don't cache requests with query strings (except for specific patterns)
    if (req.url ~ "\?" && req.url !~ "\.(css|js|png|gif|jpe?g|swf|xml|txt|pdf|ico|woff|woff2|ttf|eot)$") {
        return (pass);
    }

    # Don't cache authenticated users
    if (req.http.Authorization || req.http.Cookie ~ "customer_logged_in") {
        return (pass);
    }

    # Remove cookies for static assets
    if (req.url ~ "\.(css|js|png|gif|jpe?g|swf|xml|txt|pdf|ico|woff|woff2|ttf|eot)$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Remove Google Analytics cookies
    if (req.http.Cookie ~ "__utm") {
        set req.http.Cookie = regsuball(req.http.Cookie, "__utm[^;]+(; )?", "");
    }

    # Remove DoubleClick cookies
    if (req.http.Cookie ~ "__gads") {
        set req.http.Cookie = regsuball(req.http.Cookie, "__gads[^;]+(; )?", "");
    }

    # Remove other tracking cookies
    if (req.http.Cookie ~ "(__)?(ga|gtm)_[^;]+(; )?") {
        set req.http.Cookie = regsuball(req.http.Cookie, "(__)?(ga|gtm)_[^;]+(; )?", "");
    }

    # Remove empty cookies
    if (req.http.Cookie == "") {
        unset req.http.Cookie;
    }
}

# Handle backend response
sub vcl_backend_response {
    # Cache static assets for 1 year
    if (bereq.url ~ "\.(css|js|png|gif|jpe?g|swf|xml|txt|pdf|ico|woff|woff2|ttf|eot)$") {
        set beresp.ttl = 31536000s;
        set beresp.grace = 86400s;
        set beresp.uncacheable = false;
    }

    # Cache HTML pages for 1 hour
    elsif (bereq.url ~ "\.html$" || bereq.url ~ "^/$") {
        set beresp.ttl = 3600s;
        set beresp.grace = 300s;
        set beresp.uncacheable = false;
    }

    # Cache other content for 30 minutes
    else {
        set beresp.ttl = 1800s;
        set beresp.grace = 300s;
        set beresp.uncacheable = false;
    }

    # Add cache headers
    set beresp.http.X-Cache = "HIT";
    set beresp.http.X-Cache-Hit = "1";
}

# Handle delivery
sub vcl_deliver {
    # Remove Varnish-specific headers
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.X-Cache;
    unset resp.http.X-Cache-Hit;

    # Add cache status header
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
}

# Handle hash
sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}

# Handle miss
sub vcl_miss {
    return (fetch);
}

# Handle pass
sub vcl_pass {
    return (fetch);
}

# Handle purge
sub vcl_purge {
    return (synth(200, "Purged"));
}
