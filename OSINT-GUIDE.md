# OSINT Guide: Using Open WebUI for Investigations

This guide covers how to use this Open WebUI configuration for OSINT work effectively and safely.

## 🎯 Why This Configuration Works for OSINT

This Open WebUI setup is specifically configured for investigations:

- **No digital footprints**: Everything uses privacy-focused search engines
- **Historical data access**: Built-in Archive.org and Wayback Machine
- **Document processing that works**: Upload PDFs, Word docs, whatever - it'll extract the text
- **Academic sources**: arXiv, CrossRef for research papers
- **Social intelligence**: Reddit, GitHub without the tracking nonsense
- **Your own models**: Connect to your existing Ollama setup

### Privacy-First Search Engines
- **DuckDuckGo**: Primary privacy-focused search
- **Startpage**: Google results without tracking
- **SearX instances**: Decentralized privacy search
- **Disabled**: Google, Bing, Yahoo, Yandex (tracking engines)

### Archive & Historical Data
- **Archive.org**: Historical web content
- **Wayback Machine**: Website snapshots over time
- **Academic sources**: arXiv, CrossRef for research papers

### Social Media & Forums
- **Reddit**: Social intelligence gathering
- **GitHub/GitLab**: Code repository investigation
- **YouTube/Vimeo**: Video content analysis

### Geographic Intelligence
- **OpenStreetMap**: Location data without tracking
- **Local map services**: Privacy-focused alternatives

## 🔧 External Ollama Configuration

This setup connects to an external Ollama server instead of running it locally:

### Default Configuration
- **Primary**: `http://192.168.2.241:11434`
- **Fallback**: `http://host.docker.internal:11434` (for localhost)

### Supported Models for Investigation Work

This configuration is optimized with specific models for investigative work:

#### Primary Models

- **Default**: `gemma3:12b-it-qat` - Google's Gemma 3 12B Instruct model with QAT quantization
  - **Recommended Settings**: Max Tokens: 16000, Temperature: 0.5
  - **Best for**: Detailed analysis, report generation, complex reasoning tasks
- **Alternative**: `mistral-small-osint` - Mistral Small with anti-slop tuning for factual analysis
- **Embeddings**: `snowflake-arctic-embed2` - High-quality document embeddings for RAG

#### Quick Model Setup

```bash
# Pull the recommended models
ollama pull gemma3:12b-it-qat
ollama pull snowflake-arctic-embed2

# Optional: Mistral alternative  
ollama pull mradermacher/mistral-small-3_2-24b-instruct-2506-antislop-i1-gguf:iq4_xs
```

## 🎯 OSINT-Optimized System Prompts

Before starting investigations, configure your model with an unbiased, fact-focused system prompt:

### Recommended System Prompt for OSINT

```text
You are an OSINT (Open Source Intelligence) analyst assistant. Your role is to help with factual data investigations using only verifiable, open-source information.

Key principles:
- Provide factual, unbiased analysis based solely on available evidence
- Clearly distinguish between confirmed facts and speculation  
- Cite sources when possible and note confidence levels
- Avoid assumptions or filling gaps with unverified information
- Flag potential biases in sources or data
- Focus on verifiable, actionable intelligence
- Respect privacy and legal boundaries in investigations

When analyzing information:
1. Verify claims against multiple sources
2. Note the date and context of information
3. Identify potential conflicts of interest in sources
4. Suggest additional verification methods
5. Highlight gaps or limitations in available data

Your goal is to support thorough, ethical, and accurate open-source investigations.
```

### How to Set This Up

1. **In Open WebUI**: Go to Settings → Personalization → System Prompt
2. **Copy the prompt above** and paste it in
3. **Save** - this will apply to all new chats
4. **For existing chats**: You can manually add this prompt at the start

## 🛠️ Built-in OSINT Tools

This platform includes custom OpenAPI tool servers specifically designed for OSINT investigations. These tools require manual configuration after platform deployment.

### Critical Setup Required

**⚠️ Important**: These tools require manual import after platform deployment. The containers run automatically, but Open WebUI requires explicit function imports.

**Step 1: Import OSINT Tools**
1. Navigate to **Admin Panel** > **Tools** > **Functions**
2. Click **+ Import Function**
3. Select **Import from OpenAPI URL**
4. Enter: `http://open-webui-osint-tools:8001/openapi.json`
5. Click **Import** - should import 9 tools

**Step 2: Import MCP Tools (Optional)**
1. In the same Functions panel
2. Click **+ Import Function** again
3. Select **Import from OpenAPI URL**
4. Enter: `http://open-webui-mcp-proxy:8002/openapi.json`
5. Click **Import** - adds MCP framework tools

**Step 3: Verify Import**
- Check that tools appear in your Functions list
- Should see: Domain WHOIS, DNS Lookup, URL Analysis, Hash Tools, IP Analysis, Social Media Check, Wayback Machine, and MCP Time tools

### OSINT Tools Server

**Access**: Available as tools in chat or directly at <http://localhost:8001/docs>

**Domain Intelligence:**
- **WHOIS Lookup**: Get domain registration details, registrar, creation/expiration dates, name servers
- **DNS Analysis**: Retrieve A, AAAA, MX, NS, TXT, CNAME records for any domain
- **Use cases**: Identifying domain ownership, infrastructure analysis, finding associated assets, passive reconnaissance

**URL & Web Analysis:**
- **URL Structure Analysis**: Parse domains, subdomains, paths, query parameters automatically
- **Risk Assessment**: Detect suspicious patterns, URL shorteners, malicious indicators, excessive hyphens
- **Archive Checking**: Check Wayback Machine for historical snapshots and availability
- **Use cases**: Investigating suspicious links, tracking domain history, web forensics, phishing analysis

**Cryptographic Analysis:**
- **Hash Calculation**: Generate MD5, SHA1, SHA256, SHA512 hashes for any text input
- **Base64 Encoding/Decoding**: Handle encoded communications and data safely
- **Use cases**: File integrity verification, malware analysis, encoded message analysis, data validation

**Network Intelligence:**
- **IP Analysis**: Classify private/public IPs, perform reverse DNS lookups, version detection
- **Social Media Scanning**: Check username availability across 8 major platforms (Twitter, Instagram, GitHub, Reddit, LinkedIn, YouTube, TikTok, Facebook)
- **Use cases**: Infrastructure mapping, social media reconnaissance, identity correlation, account discovery

### MCP Tool Proxy

**Access**: Available as tools in chat or directly at <http://localhost:8002/docs>

**Time & Date Tools:**
- Current time and date information with timezone awareness
- Timezone conversions and calculations for international investigations
- **Use cases**: Timeline analysis, coordinating across time zones, temporal correlation

**File System Tools** (when enabled):
- Safe file operations and analysis within containerized environment
- **Use cases**: Document processing, file forensics, evidence handling

**Extensible Framework:**
- Add any MCP-compatible tool server via environment configuration
- Configure via `MCP_SERVER_CMD` environment variable in docker-compose.yaml
- **Use cases**: Custom tool integration, specialized investigation workflows

### Using Tools in Investigations

**Enable Tools for Each Conversation:**
1. Start a new conversation in Open WebUI
2. Click the "Tools" toggle in the chat interface (usually bottom toolbar)
3. Select which specific tools to enable for this investigation
4. Tools remain active for the duration of that conversation

**Natural Language Tool Activation:**
Ask questions that trigger tool usage automatically:

```text
"Check the WHOIS information for suspicious-domain.com"
"Analyze this URL for risk patterns: https://bit.ly/xyz123"
"Calculate the SHA256 hash of this text: [suspicious content]"
"Check if the username 'target_person' exists on social media platforms"
"Find archived versions of compromised-website.com from the Wayback Machine"
"Get DNS A and MX records for corporate-target.com"
"Is this IP address 192.168.1.100 private or public?"
"Decode this Base64 string: U3VzcGljaW91cyBkYXRh"
```

**Integration with Investigation Workflow:**
- Tools provide structured, verifiable data that integrates seamlessly with chat analysis
- Results include confidence levels and source attribution
- Data can be cross-referenced with web search and document analysis
- Tool outputs are logged for investigation documentation

### Manual Tool Testing

**Verify OSINT Tools Functionality:**

```bash
# Test the comprehensive smoke test
./test-openapi-tools.sh

# Test individual endpoints manually
curl "http://localhost:8001/tools/domain/whois?domain=example.com"
curl "http://localhost:8001/tools/domain/dns?domain=example.com&record_type=A"
curl "http://localhost:8001/tools/url/analyze?url=https://suspicious-site.com"
curl "http://localhost:8001/tools/crypto/hash?text=test"
curl "http://localhost:8001/tools/ip/analyze?ip=8.8.8.8"
curl "http://localhost:8001/tools/osint/social_media_usernames?username=testuser"
curl "http://localhost:8001/tools/osint/wayback_check?url=https://example.com"
```

**Verify MCP Proxy Functionality:**

```bash
# Test MCP proxy health
curl http://localhost:8002/health

# Test time tools (example)
curl -X POST "http://localhost:8002/mcp/tools/current_time"
```

### Tool Configuration Troubleshooting

**"Tools not showing in chat":**
1. Verify tools are imported in Admin Panel > Tools > Functions
2. Ensure "Tools" toggle is enabled in the conversation
3. Check that specific tools are selected for the conversation

**"Tool import failed":**
1. Verify containers are running: `docker compose ps`
2. Test tool endpoints directly: `curl http://localhost:8001/health`
3. Use internal Docker URLs for import:
   - **Investigation Tools**: Base URL `http://open-webui-osint-tools:8001` + Path `openapi.json`
   - **MCP Time Tools**: Base URL `http://open-webui-mcp-proxy:8002/time` + Path `openapi.json`
4. Check container logs: `docker compose logs open-webui-osint-tools`

**"Tools timing out":**
1. Check container resource allocation
2. Verify network connectivity between containers
3. Monitor tool response times: `./test-openapi-tools.sh`

**Tool results accuracy:**
- WHOIS data depends on domain registrar transparency
- DNS lookups reflect current configurations (may miss historical data)
- Social media checks are availability-based (not definitive proof of account ownership)
- Wayback Machine results depend on archive.org indexing
- Always cross-verify tool results with additional sources

**Tools integrate seamlessly with your investigation workflow and provide structured, verifiable data.**

## �📋 OSINT Investigation Workflow

### Creating Intelligence Reports

Here's a step-by-step process for generating comprehensive OSINT reports:

#### 1. Initial Subject Research

```text
Subject: [Target Person/Organization/Topic]
Research Objective: [What specific intelligence are you seeking]

Please help me conduct an OSINT investigation on [subject]. I need:
- Background information and public profile
- Associated organizations and connections  
- Digital footprint analysis
- Historical data and timeline
- Potential sources for deeper investigation

Use web search to gather initial intelligence from open sources.
```

#### 2. Deep Dive Analysis

```text
Based on the initial findings, please:
1. Cross-reference information across multiple sources
2. Identify any inconsistencies or conflicting data
3. Suggest additional search terms or investigation angles
4. Flag any information that requires further verification
5. Create a timeline of significant events or activities
```

#### 3. Report Generation

```text
Please compile the findings into a structured OSINT report with:

**Executive Summary**: Key findings in 2-3 sentences
**Subject Profile**: Verified biographical/organizational data  
**Digital Footprint**: Online presence and activities
**Associations**: Connected individuals, organizations, or entities
**Timeline**: Chronological sequence of relevant events
**Sources**: List of all sources consulted with reliability assessment
**Intelligence Gaps**: Areas requiring additional investigation
**Recommendations**: Suggested next steps or investigation priorities

Format this as a professional intelligence brief suitable for documentation.
```

### Connecting to Different Ollama Servers

#### Option 1: Local Host Machine

```bash
# In .env file
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

#### Option 2: Network Machine

```bash
# In .env file
OLLAMA_BASE_URL=http://192.168.1.100:11434
```

#### Option 3: Multiple Servers (via LiteLLM config)

Edit `open-webui-litellm-config/config.yaml`:

```yaml
model_list:
  - model_name: llama3.2-server1
    litellm_params:
      model: ollama/llama3.2
      api_base: http://192.168.2.241:11434
      
  - model_name: llama3.2-server2
    litellm_params:
      model: ollama/llama3.2
      api_base: http://192.168.2.242:11434
```

## 🔍 How to Actually Use This for OSINT

Here are some real examples of how to get useful intel with this setup.

### Person Investigation

**What you're trying to do:** Find information about someone without tipping them off

**How to do it:**

1. Start a new chat and enable "Web Search"
2. Search for: `"John Doe" site:linkedin.com OR site:twitter.com OR site:facebook.com`
3. Follow up with: `"John Doe" archived social media posts`
4. Try: `"John Doe" site:archive.org` to find old websites or deleted content

**Why this works:** You're hitting multiple privacy-focused engines and archives without directly querying the target platforms.

### Company/Domain Research

**What you're trying to do:** Get the full picture of an organization

**How to do it:**

1. Search: `example.com historical changes` 
2. Upload any PDFs/documents you find using the document upload feature
3. Ask: "Find all email addresses and technical contacts mentioned in these documents"
4. Search: `site:github.com "example.com"` to find related repositories
5. Try: `"example.com" site:reddit.com` for community discussions

### Document Analysis

**What you're trying to do:** Extract intel from files without leaving traces

**How to do it:**

1. Upload the PDF/Word doc/whatever using the paperclip icon
2. Ask: "Extract all names, dates, and locations from this document"
3. Ask: "What organizations or companies are mentioned?"
4. For each entity found, do follow-up searches using the web search feature

### Technical Investigation

**What you're trying to do:** Research vulnerabilities, code, or technical details

**How to do it:**

1. Search: `CVE-2023-12345 site:github.com`
2. Search: `"specific error message" site:reddit.com OR site:stackoverflow.com`
3. Use arXiv search for: `academic papers about [technology]`

## 🛡️ Privacy & Security Features

### Network Isolation
- All services communicate internally
- External connections only to specified Ollama server
- No telemetry or tracking enabled

### Data Protection
- Redis cache with TTL for sensitive data
- Document processing via local Tika server
- No data sharing with external services

### Access Control
- Authentication required (configurable)
- User registration disabled by default
- Session security hardened

## 📊 Performance Optimization for OSINT

### Search Configuration
- **Results per query**: 15 (increased for comprehensive coverage)
- **Concurrent requests**: 8 (balanced for stability)
- **Cache TTL**: 1 hour (preserves investigation data)

### Resource Allocation
- **Redis**: 512MB for larger cache (OSINT data)
- **Tika**: 1GB heap for document processing
- **SearXNG**: 6 workers for high-volume searches

## 🚨 OSINT Best Practices

### Search Hygiene
1. **Use VPN**: Route traffic through privacy networks
2. **Rotate queries**: Vary search terms to avoid patterns
3. **Time delays**: Space out searches to avoid rate limiting
4. **Archive results**: Save important findings immediately

### Data Validation
1. **Cross-reference**: Verify across multiple sources
2. **Time stamps**: Check data freshness and historical context
3. **Source credibility**: Evaluate information quality
4. **Documentation**: Maintain investigation trails

### Legal Considerations
1. **Jurisdiction**: Understand legal boundaries
2. **Terms of service**: Respect platform limitations
3. **Data sensitivity**: Handle personal information appropriately
4. **Documentation**: Maintain proper investigation records

## 🔧 Troubleshooting OSINT Setup

### External Ollama Connectivity
```bash
# Test from host
curl http://192.168.2.241:11434/api/tags

# Test from container
docker-compose exec open-webui-litellm curl http://192.168.2.241:11434/api/tags
```

### SearXNG Engine Status
```bash
# Check enabled engines
curl "http://localhost:8080/search?q=test&format=json" | jq '.engines'

# Test specific engine
curl "http://localhost:8080/search?q=test&engines=duckduckgo&format=json"
```

### Performance Monitoring
```bash
# Check search response times
docker-compose logs open-webui-searxng | grep "response_time"

# Monitor resource usage
docker stats open-webui-redis open-webui-searxng open-webui-tika
```

## 📈 Scaling for Large OSINT Operations

### Horizontal Scaling
- Multiple SearXNG instances with load balancing
- Distributed Redis cluster for caching
- Separate Tika servers for document processing

### Vertical Scaling
- Increase worker counts in SearXNG
- Allocate more memory to Redis and Tika
- Optimize network connectivity to Ollama servers

### Data Management
- Implement data retention policies
- Regular cache cleanup for sensitive investigations
- Automated backup of important findings

## 🎯 Practical OSINT Tool Usage Examples

### Domain Investigation Workflow

**Scenario**: Investigating a suspicious domain for phishing or malware

```text
1. "Check WHOIS information for suspicious-domain.com"
   - Reveals registration date, registrar, nameservers
   - Look for recent registration (red flag for phishing)
   - Note privacy-protected vs. public registration data

2. "Get DNS A, MX, and NS records for suspicious-domain.com"
   - Identify hosting infrastructure and mail servers
   - Compare with known legitimate domains
   - Look for shared hosting with other suspicious domains

3. "Analyze this URL for suspicious patterns: https://suspicious-domain.com/login"
   - Detects URL shorteners, suspicious TLDs, long domain names
   - Identifies path structures mimicking legitimate sites
   - Flags potential typosquatting attempts

4. "Check Wayback Machine for historical versions of suspicious-domain.com"
   - Determine when domain was first archived
   - Identify changes in content or purpose over time
   - Find original or legitimate content before compromise
```

### Social Media Reconnaissance

**Scenario**: Investigating an individual's online presence

```text
1. "Check if username 'target_username' exists on social media platforms"
   - Systematically checks 8 major platforms
   - Identifies consistent username usage patterns
   - Reveals platform preferences and activity levels

2. Cross-reference findings:
   - Search: "target_username site:reddit.com" for post history
   - Search: "target_username site:github.com" for technical profiles
   - Upload any documents for name/email extraction
   - Use hash tools to verify file integrity if suspicious
```

### Cryptographic Analysis for Evidence

**Scenario**: Analyzing suspicious files or communications

```text
1. "Calculate SHA256 hash of this file content: [paste content]"
   - Generate unique file fingerprint for evidence chain
   - Compare against known malware databases
   - Verify file integrity across different sources

2. "Decode this Base64 string: [suspicious encoded data]"
   - Reveal hidden communications or embedded data
   - Analyze encoded payloads in phishing emails
   - Decode configuration data from malware samples

3. Cross-verify with web search:
   - Search the calculated hash on VirusTotal or threat intel feeds
   - Search decoded content for additional context
```

### Infrastructure Mapping

**Scenario**: Mapping an organization's digital footprint

```text
1. "Analyze IP address 203.0.113.42"
   - Classify as public/private, determine IP version
   - Perform reverse DNS lookup for associated domains
   - Identify hosting provider or organization

2. "Get DNS records for corporate-domain.com"
   - Map email infrastructure (MX records)
   - Identify subdomains and services (A/AAAA records)
   - Find CDN and security services (CNAME records)
   - Analyze SPF/DKIM/DMARC policies (TXT records)

3. Timeline correlation:
   - Use MCP time tools for timezone conversion
   - Correlate registration dates with business events
   - Map infrastructure changes over time
```

## 🚨 OSINT Tool Best Practices

### Data Validation and Cross-Referencing

**Always verify tool results:**
- WHOIS data may be privacy-protected or outdated
- DNS records change frequently and may not reflect historical data
- Social media availability doesn't confirm account ownership
- Wayback Machine snapshots may be incomplete or missing

**Cross-reference methodology:**
1. Use multiple tools for same investigation target
2. Correlate tool results with web search findings
3. Verify against authoritative sources when possible
4. Document confidence levels for each data point

### Operational Security

**Tool usage patterns:**
- Space out queries to avoid rate limiting or detection
- Use different investigation sessions for unrelated targets
- Clear tool caches between sensitive investigations
- Monitor tool response times for performance anomalies

**Data handling:**
- Screenshot or save tool results for evidence documentation
- Use hash verification for file integrity throughout investigation
- Maintain investigation logs with tool result timestamps
- Sanitize data before sharing or reporting

### Integration with Traditional OSINT

**Combine tool results with manual techniques:**
- Use tool-generated leads for deeper manual investigation
- Verify automated findings through human analysis
- Combine technical data with open source research
- Cross-reference digital footprints with physical world data

**Investigation workflow optimization:**
1. Start with broad automated tool sweeps
2. Focus manual effort on high-confidence tool results
3. Use tools to verify manually discovered information
4. Document complete methodology for reproducibility

## 🤝 OSINT Community Integration

### Sharing Configurations
- Export search engine configurations
- Share custom engine definitions
- Collaborate on investigation methodologies

### Tool Integration
- API endpoints for external OSINT tools
- Export search results in various formats
- Integration with evidence management systems
- OpenAPI specifications for custom tool development

### Contributing Tool Improvements
- Report tool accuracy issues or false positives
- Suggest additional OSINT tools for integration
- Share custom MCP server configurations
- Contribute to community knowledge base

## Conclusion

This Open WebUI configuration provides a powerful foundation for OSINT investigations while maintaining privacy and operational security. The combination of specialized tools, privacy-focused search engines, and local AI processing creates an effective investigation environment.

**Remember**: Always verify information through multiple sources and maintain awareness of legal and ethical boundaries in your investigations.

---

**Author**: rick@osintweaver  
**Provided without warranty by OSINTWEAVER**
