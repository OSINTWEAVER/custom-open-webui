FROM python:3.11-slim

WORKDIR /app

# Install uv for faster package management and curl for healthcheck
RUN pip install uv && apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Install mcpo and available MCP servers
RUN uv pip install --system mcpo mcp-server-time

# Install additional useful MCP servers (using || true to continue if some fail)
RUN uv pip install --system mcp-server-git mcp-server-sqlite || true

# Create entrypoint script and config
COPY entrypoint.sh /entrypoint.sh
COPY config.json /app/config.json
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Expose the port
EXPOSE 8002

# Health check with curl (avoid python requests dependency)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:8002/docs >/dev/null || exit 1

# Use entrypoint
ENTRYPOINT ["/entrypoint.sh"]
