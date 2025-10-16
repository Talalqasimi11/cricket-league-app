## Stack
- Flutter for app (Provider, flutter_secure_storage)
- Node.js + Express + JWT + Socket.IO for backend
- MySQL (PlanetScale-compatible)

This repo follows a trunk-based workflow with main/dev branches and feature branches.

## Environment Variables (Backend)

Set these in `backend/.env`:

```
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000

JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

# Comma-separated list of exact origins (no wildcard when credentials are used)
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000

# Cookie flags
NODE_ENV=development
COOKIE_SECURE=false
# Optional: set to true to rotate refresh tokens on each use
ROTATE_REFRESH_ON_USE=false
```

Notes:
- Refresh flow accepts `refresh_token` in the request body (mobile-friendly).
- Cookies use `sameSite=lax` and `secure` only in production; adjust via `COOKIE_SECURE`.
- Configure `CORS_ORIGINS` explicitly when `credentials: true`.
- For Android emulator, Flutter automatically uses `http://10.0.2.2:5000` as base URL.
- To override API URL at build time: `flutter run --dart-define=API_BASE_URL=http://your-custom-url:5000`

## Health Check

Backend exposes `GET /health` returning status and DB connectivity.
