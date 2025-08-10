FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (curl used in healthcheck)
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application
COPY osint_tools_server.py .

# Expose the port
EXPOSE 8001

# Health check with curl (avoid python dependencies in healthcheck)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -fsS http://localhost:8001/health >/dev/null || exit 1

# Run the application
CMD ["python", "osint_tools_server.py"]
