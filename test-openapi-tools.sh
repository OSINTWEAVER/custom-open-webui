#!/bin/bash

# OpenAPI Tools Smoke Test Script
# Tests all OSINT tools and MCP proxy endpoints

echo "🔍 OSINT Platform OpenAPI Tools Smoke Test"
echo "==========================================="

# Configuration
OSINT_TOOLS_URL="http://localhost:8001"
MCP_PROXY_URL="http://localhost:8002"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test an endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" -eq "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $response)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $response, expected $expected_status)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to check if service is running
check_service() {
    local name="$1"
    local url="$2"
    
    echo "🔍 Checking $name..."
    
    if curl -s --connect-timeout 5 "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $name is not accessible${NC}"
        return 1
    fi
}

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 5

# Check if services are running
echo ""
echo "📡 Service Health Checks"
echo "------------------------"

OSINT_TOOLS_RUNNING=false
MCP_PROXY_RUNNING=false

if check_service "OSINT Tools Server" "$OSINT_TOOLS_URL/health"; then
    OSINT_TOOLS_RUNNING=true
fi

if check_service "MCP Proxy Server" "$MCP_PROXY_URL/docs"; then
    MCP_PROXY_RUNNING=true
fi

echo ""

# Test OSINT Tools if running
if [ "$OSINT_TOOLS_RUNNING" = true ]; then
    echo "🛠️  Testing OSINT Tools Server"
    echo "-----------------------------"
    
    # Health check
    test_endpoint "Health Check" "$OSINT_TOOLS_URL/health" 200
    
    # Domain tools
    test_endpoint "Domain WHOIS" "$OSINT_TOOLS_URL/tools/domain/whois?domain=example.com" 200
    test_endpoint "DNS Lookup" "$OSINT_TOOLS_URL/tools/domain/dns?domain=example.com&record_type=A" 200
    
    # URL analysis
    test_endpoint "URL Analysis" "$OSINT_TOOLS_URL/tools/url/analyze?url=https://example.com/test" 200
    
    # Crypto tools
    test_endpoint "Hash Calculation" "$OSINT_TOOLS_URL/tools/crypto/hash?text=test" 200
    test_endpoint "Base64 Encode" "$OSINT_TOOLS_URL/tools/crypto/base64_encode?plain_text=test" 200
    test_endpoint "Base64 Decode" "$OSINT_TOOLS_URL/tools/crypto/base64_decode?encoded_text=dGVzdA==" 200
    
    # IP analysis
    test_endpoint "IP Analysis" "$OSINT_TOOLS_URL/tools/ip/analyze?ip=8.8.8.8" 200
    
    # OSINT utilities
    test_endpoint "Social Media Check" "$OSINT_TOOLS_URL/tools/osint/social_media_usernames?username=test" 200
    test_endpoint "Wayback Machine Check" "$OSINT_TOOLS_URL/tools/osint/wayback_check?url=https://example.com" 200
    
    echo ""
else
    echo -e "${YELLOW}⚠️  Skipping OSINT Tools tests (service not running)${NC}"
    echo ""
fi

# Test MCP Proxy if running
if [ "$MCP_PROXY_RUNNING" = true ]; then
    echo "🔗 Testing MCP Proxy Server"
    echo "---------------------------"
    
    # OpenAPI docs
    test_endpoint "OpenAPI Documentation" "$MCP_PROXY_URL/docs" 200
    
    # Try to get available endpoints
    test_endpoint "OpenAPI Schema" "$MCP_PROXY_URL/openapi.json" 200
    
    echo ""
else
    echo -e "${YELLOW}⚠️  Skipping MCP Proxy tests (service not running)${NC}"
    echo ""
fi

# Test results summary
echo "📊 Test Results Summary"
echo "======================"
echo -e "Total tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ] && [ $TESTS_TOTAL -gt 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! OpenAPI tools are working correctly.${NC}"
    exit 0
elif [ $TESTS_TOTAL -eq 0 ]; then
    echo -e "\n${YELLOW}⚠️  No tests were run. Please check that services are running.${NC}"
    exit 1
else
    echo -e "\n${RED}❌ Some tests failed. Please check the logs for more details.${NC}"
    exit 1
fi
