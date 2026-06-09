# ArgusX VPS Deployment & CI/CD

| Domain | Role | VPS path | App process | Public edge |
|--------|------|----------|-------------|-------------|
| **argusx.codemelodies.com** | Next.js admin portal | `/var/www/html/argusx.codemelodies.com` | **PM2** (auto free port **3100–8999**) | **Apache2** reverse proxy |
| **argusx-api.codemelodies.com** | FastAPI orchestrator + WebSocket | `/var/www/html/argusx-api.codemelodies.com` | **systemd** → **uvicorn** `:8025` | **Apache2** reverse proxy |

```
Internet → Apache2 (80/443)
              ├─ argusx.codemelodies.com     → PM2 Node (dynamic port)
              └─ argusx-api.codemelodies.com → uvicorn 127.0.0.1:8025
```

**Shared VPS:** This host already uses many ports (e.g. 3000–3015, 5000–5005, 6001, 8000, 8002, 8010, 8080). ArgusX avoids them — see `deploy/argusx-ports.conf`. Check listeners with `sudo ss -tlnp`.

Workflows: `.github/workflows/deploy-web.yml`, `.github/workflows/deploy-api.yml`

---

## Step 1 — Deploy SSH key on VPS

```powershell
ssh -p 2221 -i "$env:USERPROFILE\.ssh\kamovhwebadmin" webadmin@137.74.41.148
```

On the **VPS**:

```bash
ssh-keygen -t ed25519 -C "github-actions-argusx" -f ~/.ssh/argusx-access -N ""

mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
cat ~/.ssh/argusx-access.pub >> ~/.ssh/authorized_keys

# Paste into GitHub secret ARGUSX_VPS_SSH_KEY:
cat ~/.ssh/argusx-access
```

---

## Step 2 — GitHub secrets

| Secret | Value |
|--------|--------|
| `ARGUSX_VPS_HOST` | `137.74.41.148` |
| `ARGUSX_VPS_PORT` | `2221` |
| `ARGUSX_VPS_USER` | `webadmin` |
| `ARGUSX_VPS_SSH_KEY` | Private key from `cat ~/.ssh/argusx-access` |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |

---

## Step 3 — One-time VPS bootstrap

```bash
sudo mkdir -p /var/www/html/argusx-deploy /var/www/html/argusx.codemelodies.com /var/www/html/argusx-api.codemelodies.com
sudo chown -R webadmin:webadmin /var/www/html/argusx-deploy /var/www/html/argusx.codemelodies.com /var/www/html/argusx-api.codemelodies.com

sudo apt update
sudo apt install -y python3 python3-venv python3-pip apache2
node -v || (curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs)
sudo npm install -g pm2
pm2 startup    # run the sudo command it prints
```

### Apache modules

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers ssl
sudo a2dissite 000-default.conf 2>/dev/null || true
```

### Virtual hosts

```bash
sudo cp /var/www/html/argusx-deploy/apache/argusx-api.codemelodies.com.conf.example \
  /etc/apache2/sites-available/argusx-api.codemelodies.com.conf
sudo cp /var/www/html/argusx-deploy/apache/argusx.codemelodies.com.conf.example \
  /etc/apache2/sites-available/argusx.codemelodies.com.conf
sudo cp /var/www/html/argusx-deploy/apache/argusx-web-proxy.conf \
  /var/www/html/argusx-deploy/apache/argusx-web-proxy.conf

sudo a2ensite argusx-api.codemelodies.com.conf argusx.codemelodies.com.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

TLS (when DNS is ready):

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d argusx.codemelodies.com -d argusx-api.codemelodies.com
```

### Backend `.env` (never commit)

```bash
nano /var/www/html/argusx-api.codemelodies.com/.env
```

```env
ARGUSX_ENVIRONMENT=production
ARGUSX_DEBUG=false
ARGUSX_HOST=127.0.0.1
ARGUSX_PORT=8025
ARGUSX_CORS_ORIGINS=https://argusx.codemelodies.com
ARGUSX_SUPABASE_URL=...
ARGUSX_SUPABASE_KEY=...
ARGUSX_GEMINI_API_KEY=...
ARGUSX_GOOGLE_MAPS_API_KEY=...
ARGUSX_COMPLIANCE_SERVICE_URL=http://127.0.0.1:8081
```

### systemd — uvicorn API

```bash
sudo cp /var/www/html/argusx-deploy/systemd/argusx-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable argusx-api
sudo systemctl start argusx-api
sudo systemctl status argusx-api
```

Uvicorn binds **127.0.0.1:8025** only — Apache is the public entrypoint.

---

## PM2 web portal (auto port)

Each web deploy:

1. Scans **3100–8999** with `ss` and picks the first free port (reuses `.runtime-port` when still free)
2. Starts **`pm2 argusx-web`**
3. Writes `/var/www/html/argusx-deploy/apache/argusx-web-proxy.conf`
4. Reloads **apache2**

```bash
pm2 list
pm2 logs argusx-web --lines 50
cat /var/www/html/argusx.codemelodies.com/.runtime-port
cat /var/www/html/argusx-deploy/apache/argusx-web-proxy.conf
```

---

## Client URLs (production)

| Client | API | WebSocket |
|--------|-----|-----------|
| Flutter APK | `https://argusx-api.codemelodies.com` | `wss://argusx-api.codemelodies.com/ws/pulse` |
| Next.js web | same | same |

Local dev: `--dart-define` (Flutter) or `.env.local` (Web) → `127.0.0.1:8000`

---

## Verify

```bash
curl https://argusx-api.codemelodies.com/health
curl -I https://argusx.codemelodies.com
sudo systemctl status argusx-api
pm2 status argusx-web
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API 502 | `sudo systemctl status argusx-api` — uvicorn running? `.env` present? |
| Web 502 | `pm2 logs argusx-web`; check `argusx-web-proxy.conf` port |
| WebSocket fail | `sudo a2enmod proxy_wstunnel rewrite`; reload apache2 |
| Apache config error | `sudo apache2ctl configtest` |
| Port clash | `sudo ss -tlnp`; remove `.runtime-port` and redeploy web; API is fixed on **8025** |
