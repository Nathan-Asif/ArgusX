# ArgusX Apache2 + SSL setup (Hostinger DNS → VPS)

## 1. Enable modules

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers ssl
sudo a2dissite 000-default.conf 2>/dev/null || true
```

## 2. Phase A — HTTP only (until certificate exists)

```bash
sudo cp /var/www/html/argusx-deploy/apache/argusx-api.codemelodies.com.conf.http-only \
  /etc/apache2/sites-available/argusx-api.codemelodies.com.conf
sudo cp /var/www/html/argusx-deploy/apache/argusx.codemelodies.com.conf.http-only \
  /etc/apache2/sites-available/argusx.codemelodies.com.conf

sudo a2ensite argusx-api.codemelodies.com.conf argusx.codemelodies.com.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

Verify HTTP works:

```bash
curl -I http://argusx-api.codemelodies.com/health
curl -I http://argusx.codemelodies.com
```

## 3. Generate SSL (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-apache

sudo certbot --apache \
  -d argusx.codemelodies.com \
  -d argusx-api.codemelodies.com \
  --email YOUR_EMAIL@example.com \
  --agree-tos \
  --no-eff-email \
  --redirect
```

Certbot will create `/etc/letsencrypt/live/argusx.codemelodies.com/` (one cert, both names).

## 4. Phase B — Full SSL vhosts (optional — replace certbot edits)

If you want the repo-managed configs with explicit WebSocket rules:

```bash
sudo cp /var/www/html/argusx-deploy/apache/argusx-api.codemelodies.com.conf \
  /etc/apache2/sites-available/argusx-api.codemelodies.com.conf
sudo cp /var/www/html/argusx-deploy/apache/argusx.codemelodies.com.conf \
  /etc/apache2/sites-available/argusx.codemelodies.com.conf

sudo apache2ctl configtest && sudo systemctl reload apache2
```

## 5. Verify HTTPS

```bash
curl https://argusx-api.codemelodies.com/health
curl -I https://argusx.codemelodies.com
sudo certbot renew --dry-run
```
