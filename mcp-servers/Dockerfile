FROM python:3.11-slim

WORKDIR /app

# Install uv for faster package management
RUN pip install uv

# Install mcpo and available MCP servers
RUN uv pip install --system mcpo mcp-server-time

# Install additional useful MCP servers (using || true to continue if some fail)
RUN uv pip install --system mcp-server-git mcp-server-sqlite || true

# Create entrypoint script and config
COPY entrypoint.sh /entrypoint.sh
COPY config.json /app/config.json
RUN chmod +x /entrypoint.sh

# Expose the port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8002/docs')"

# Use entrypoint
ENTRYPOINT ["/entrypoint.sh"]
