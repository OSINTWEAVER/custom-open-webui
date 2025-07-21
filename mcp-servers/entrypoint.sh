#!/bin/bash

# Default MCP server command if none provided
DEFAULT_MCP_SERVER="uv run mcp-server-time --local-timezone=UTC"

# Use provided command or default
MCP_SERVER_CMD="${MCP_SERVER_CMD:-$DEFAULT_MCP_SERVER}"

echo "Starting MCP-to-OpenAPI proxy with server: $MCP_SERVER_CMD"

# Start mcpo with the specified MCP server
exec uv run mcpo --host 0.0.0.0 --port 8002 -- $MCP_SERVER_CMD
