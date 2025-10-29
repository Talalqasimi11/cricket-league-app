# Quick Start Guide

Get up and running with the Cricket League Management Application in minutes.

## Prerequisites Check

Before starting, ensure you have:

- [x] Node.js v18+ installed (`node --version`)
- [x] MySQL installed and running
- [x] Flutter SDK installed (for mobile app)
- [x] Git installed

## 5-Minute Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/cricket-league-app.git
cd cricket-league-app
```

### Step 2: Setup Database

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE cricket_league;"

# Import schema
mysql -u root -p cricket_league < cricket-league-db/schema.sql
```

### Step 3: Configure Backend

```bash
cd backend

# Create .env file
cat > .env << 'EOF'
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000
NODE_ENV=development
JWT_SECRET=your_super_secret_jwt_key_at_least_32_chars_long
JWT_REFRESH_SECRET=your_super_secret_refresh_key_at_least_32_chars_long
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000
COOKIE_SECURE=false
ROTATE_REFRESH_ON_USE=false
RETURN_RESET_TOKEN_IN_BODY=false
EOF

# Install dependencies
npm install

# Start server
npm start
```

**Expected Output:**
```
Server running on http://localhost:5000
Database connected successfully
CORS enabled for origins: ...
```

### Step 4: Test the Backend

```bash
# In a new terminal
curl http://localhost:5000/health
```

You should see:
```json
{"status":"ok","version":"dev","db":"up"}
```

### Step 5: Setup Mobile App (Optional)

```bash
cd ../frontend

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

### Step 6: Setup Admin Panel (Optional)

```bash
cd ../admin-panel

# Create .env file
echo "REACT_APP_API_URL=http://localhost:5000/api" > .env

# Install dependencies
npm install

# Start development server
npm start
```

Admin panel will open at `http://localhost:3000`

---

## First Steps After Setup

### 1. Register a Test User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890",
    "password": "test1234",
    "captain_name": "Test User"
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890",
    "password": "test1234"
  }'
```

Save the `access_token` from the response.

### 3. View Your Team

```bash
curl -X GET http://localhost:5000/api/teams/my-team \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Common Commands

### Backend

```bash
cd backend

# Start server
npm start

# Run in development mode (auto-reload)
npm run dev

# Run tests
npm test

# Check server health
curl http://localhost:5000/health
```

### Frontend

```bash
cd frontend

# Run app
flutter run

# Build for Android
flutter build apk

# Run tests
flutter test
```

### Admin Panel

```bash
cd admin-panel

# Start development server
npm start

# Build for production
npm run build
```

---

## Troubleshooting

### Backend Not Starting?

1. Check if MySQL is running:
   ```bash
   mysql --version
   ```

2. Verify database credentials in `backend/.env`

3. Check if port 5000 is available:
   ```bash
   lsof -i :5000  # macOS/Linux
   netstat -ano | findstr :5000  # Windows
   ```

### Database Connection Error?

```bash
# Test MySQL connection
mysql -u root -p -e "SELECT 1"

# Re-import schema
mysql -u root -p cricket_league < cricket-league-db/schema.sql
```

### Flutter Build Errors?

```bash
cd frontend

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### CORS Errors?

Add your origin to `CORS_ORIGINS` in `backend/.env`:
```
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://YOUR_IP:5000
```

Restart the backend server.

---

## Next Steps

Now that you're up and running:

1. **Read the Full Documentation**: See [DOCUMENTATION.md](DOCUMENTATION.md)
2. **Explore the API**: Check [API_REFERENCE.md](API_REFERENCE.md)
3. **Review the PRD**: Understand the requirements in [PRD.md](PRD.md)
4. **Run Tests**: Ensure everything works with `npm test` in backend
5. **Create Your First Tournament**: Use the API or mobile app

---

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/my-new-feature
```

### 2. Make Changes

Edit files, add new endpoints, create UI components, etc.

### 3. Test Your Changes

```bash
# Backend tests
cd backend && npm test

# Frontend tests
cd frontend && flutter test
```

### 4. Commit and Push

```bash
git add .
git commit -m "feat: Add my new feature"
git push origin feature/my-new-feature
```

### 5. Create Pull Request

Open a pull request on GitHub for review.

---

## Environment Configuration

### Development

- `NODE_ENV=development`
- More lenient validation
- Debug logging enabled
- Auto-created test user

### Production

- `NODE_ENV=production`
- Strict validation
- Error logging only
- Secure cookies enabled

---

## Useful Links

- [Full Documentation](DOCUMENTATION.md)
- [API Reference](API_REFERENCE.md)
- [Product Requirements](PRD.md)
- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)
- [Admin Panel README](admin-panel/README.md)

---

## Getting Help

- Check the troubleshooting section in [DOCUMENTATION.md](DOCUMENTATION.md)
- Review server logs for errors
- Check browser console (F12) for frontend issues
- Open an issue on GitHub

---

**Welcome to Cricket League Management Application!**

Happy coding! 🏏

