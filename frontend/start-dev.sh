#!/bin/bash
# Start crop-ai frontend development stack

echo "🚀 Starting crop-ai Frontend Development Stack"
echo ""

# Check if we're in the frontend directory
if [ ! -f "manage.py" ]; then
    echo "❌ Error: manage.py not found. Please run this script from the frontend directory."
    exit 1
fi

# Create static directory if it doesn't exist
mkdir -p static
mkdir -p media

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    python -m venv .venv
    source .venv/bin/activate
    echo "📥 Installing Python dependencies..."
    pip install -r requirements.txt
else
    source .venv/bin/activate
fi

# Check if Angular dependencies are installed
if [ ! -d "angular/node_modules" ]; then
    echo "📥 Installing Angular dependencies..."
    cd angular
    npm install
    cd ..
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Starting servers..."
echo ""

# Function to handle cleanup
cleanup() {
    echo ""
    echo "🛑 Shutting down servers..."
    kill $DJANGO_PID $NG_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start Django server
echo "📘 Starting Django server on http://localhost:8000"
python manage.py runserver 0.0.0.0:8000 &
DJANGO_PID=$!

sleep 2

# Start Angular development server
echo "📗 Starting Angular dev server on http://localhost:4200"
cd angular
npm start &
NG_PID=$!
cd ..

echo ""
echo "✨ Servers are running!"
echo ""
echo "Frontend: http://localhost:4200"
echo "Backend:  http://localhost:8000"
echo "Admin:    http://localhost:8000/admin"
echo "API:      http://localhost:8000/api"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Wait for both processes
wait
