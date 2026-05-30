# Use a Python image that is lightweight but supports heavy ML libraries
FROM python:3.11-slim

# Install system dependencies required by OpenCV, MediaPipe, etc.
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the custom backend requirements first to leverage Docker cache
COPY custom_backend/requirements.txt .

# Install Python dependencies
# Increased timeout for large packages like PyTorch
RUN pip install --no-cache-dir -r requirements.txt --default-timeout=100

# Copy the backend code and the radiology module
COPY custom_backend/ ./custom_backend/
COPY ["radilogy repoprt generation/", "./radilogy repoprt generation/"]

# Set the working directory to custom_backend so relative paths in main.py work
WORKDIR /app/custom_backend

# Make sure temp directories exist
RUN mkdir -p temp temp_charts

# Expose port (Railway will override this with its own PORT env var, but it's good practice)
EXPOSE 8000

# Start the FastAPI server
# Using $PORT variable which Railway sets automatically, defaulting to 8000 if not set
CMD sh -c "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"
