#!/bin/bash

# Cricket League App Test Runner
# This script provides an easy way to run different types of tests

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command_exists node; then
        missing_deps+=("Node.js")
    fi
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    if ! command_exists mysql; then
        missing_deps+=("MySQL")
    fi
    
    if ! command_exists flutter; then
        missing_deps+=("Flutter")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and try again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install root dependencies
    if [ -f "package.json" ]; then
        npm install
        print_success "Root dependencies installed"
    fi
    
    # Install backend dependencies
    if [ -d "backend" ] && [ -f "backend/package.json" ]; then
        cd backend
        npm install
        cd ..
        print_success "Backend dependencies installed"
    fi
    
    # Install frontend dependencies
    if [ -d "frontend" ] && [ -f "frontend/pubspec.yaml" ]; then
        cd frontend
        flutter pub get
        cd ..
        print_success "Frontend dependencies installed"
    fi
}

# Function to setup test environment
setup_environment() {
    print_status "Setting up test environment..."
    
    # Check if .env file exists in backend
    if [ ! -f "backend/.env" ]; then
        print_warning "Backend .env file not found. Creating template..."
        cat > backend/.env << EOF
DB_HOST=localhost
DB_USER=root
DB_PASS=your_password
DB_NAME=cricket_league
PORT=5000

JWT_SECRET=your_long_random_secret_at_least_32_chars
JWT_REFRESH_SECRET=your_long_random_refresh_secret_at_least_32_chars
JWT_AUD=cric-league-app
JWT_ISS=cric-league-auth

CORS_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000,http://10.0.2.2:5000

NODE_ENV=development
COOKIE_SECURE=false
ROTATE_REFRESH_ON_USE=false
EOF
        print_warning "Please update backend/.env with your database credentials"
    fi
    
    # Check if database exists
    if ! mysql -u root -p -e "USE cricket_league;" 2>/dev/null; then
        print_warning "Database 'cricket_league' does not exist."
        print_status "Creating database..."
        mysql -u root -p -e "CREATE DATABASE cricket_league;"
        
        if [ -f "cricket-league-db/schema.sql" ]; then
            print_status "Importing database schema..."
            mysql -u root -p cricket_league < cricket-league-db/schema.sql
            print_success "Database schema imported"
        fi
    fi
    
    print_success "Test environment setup completed"
}

# Function to start backend server
start_backend() {
    print_status "Starting backend server..."
    
    # Check if server is already running
    if lsof -ti:5000 >/dev/null 2>&1; then
        print_warning "Port 5000 is already in use. Killing existing processes..."
        lsof -ti:5000 | xargs kill -9 2>/dev/null || true
    fi
    
    # Start backend server in background
    cd backend
    npm start > ../backend.log 2>&1 &
    BACKEND_PID=$!
    cd ..
    
    # Wait for server to start
    print_status "Waiting for backend server to start..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:5000/health >/dev/null 2>&1; then
            print_success "Backend server is running (PID: $BACKEND_PID)"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    print_error "Backend server failed to start"
    return 1
}

# Function to stop backend server
stop_backend() {
    print_status "Stopping backend server..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    # Kill any process on port 5000
    lsof -ti:5000 | xargs kill -9 2>/dev/null || true
    
    print_success "Backend server stopped"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    # Run the custom test runner
    if [ -f "test-cricket-app.js" ]; then
        node test-cricket-app.js
    else
        print_error "Test runner not found. Please ensure test-cricket-app.js exists."
        return 1
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Stop backend server
    stop_backend
    
    # Clean up test data
    if [ -f "test-cleanup.js" ]; then
        node test-cleanup.js
    fi
    
    # Remove log files
    rm -f backend.log
    
    print_success "Cleanup completed"
}

# Function to show help
show_help() {
    echo "Cricket League App Test Runner"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup     - Set up test environment (install deps, create DB, etc.)"
    echo "  test      - Run tests (assumes environment is set up)"
    echo "  full      - Full test suite (setup + test + cleanup)"
    echo "  backend   - Test backend only"
    echo "  frontend  - Test frontend only"
    echo "  cleanup   - Clean up test environment"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup    # Set up test environment"
    echo "  $0 test     # Run tests"
    echo "  $0 full     # Complete test suite"
    echo "  $0 cleanup  # Clean up after tests"
}

# Main script logic
main() {
    case "${1:-help}" in
        "setup")
            check_prerequisites
            install_dependencies
            setup_environment
            ;;
        "test")
            start_backend
            run_tests
            stop_backend
            ;;
        "full")
            check_prerequisites
            install_dependencies
            setup_environment
            start_backend
            run_tests
            cleanup
            ;;
        "backend")
            start_backend
            cd backend && npm test
            stop_backend
            ;;
        "frontend")
            cd frontend && flutter test
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "$@"
