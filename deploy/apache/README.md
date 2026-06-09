# ArgusX Apache2 configs

Copy to `/etc/apache2/sites-available/` after first CI deploy copies `deploy/` to the VPS.

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers ssl
sudo cp argusx-api.codemelodies.com.conf.example /etc/apache2/sites-available/argusx-api.codemelodies.com.conf
sudo cp argusx.codemelodies.com.conf.example /etc/apache2/sites-available/argusx.codemelodies.com.conf
sudo a2ensite argusx-api.codemelodies.com.conf argusx.codemelodies.com.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

`argusx-web-proxy.conf` is auto-updated by PM2 post-deploy with the live Node port (scans **3100–8999**, skips ports already in use).

API uvicorn uses fixed port **8025** (`deploy/argusx-ports.conf`) — not 8000/8010/8080 on this shared VPS.
