# OSINT Guide: Actually Using This Thing for Investigations

So you've got the platform running - now what? This guide covers how to actually use this setup for real OSINT work without shooting yourself in the foot.

## 🎯 Why This Setup Rocks for OSINT

Look, most AI platforms are built for general chatbots or coding help. This one is specifically configured for investigations:

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

### Supported Models for OSINT

This platform is configured with specific models optimized for investigative work:

#### Primary Models

- **Default**: `gemma3:12b-it-q8_0` - Google's Gemma 3 12B Instruct model with Q8 quantization
- **Alternative**: `mistral-small-osint` - Mistral Small with anti-slop tuning for factual analysis
- **Embeddings**: `snowflake-arctic-embed2` - High-quality document embeddings for RAG

#### Quick Model Setup

```bash
# Pull the recommended models
ollama pull gemma3:12b-it-q8_0
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

## �️ Built-in OSINT Tools

This platform includes custom OpenAPI tool servers specifically designed for OSINT investigations. These tools are automatically available in your chats.

### OSINT Tools Server

**Access**: Available as tools in chat or directly at <http://localhost:8001/docs>

**Domain Intelligence:**
- **WHOIS Lookup**: Get domain registration details, registrar, creation/expiration dates
- **DNS Analysis**: Retrieve A, AAAA, MX, NS, TXT, CNAME records for any domain
- Use for: Identifying domain ownership, infrastructure analysis, finding associated assets

**URL & Web Analysis:**
- **URL Structure Analysis**: Parse domains, subdomains, paths, query parameters
- **Risk Assessment**: Detect suspicious patterns, URL shorteners, malicious indicators
- **Archive Checking**: Check Wayback Machine for historical snapshots
- Use for: Investigating suspicious links, tracking domain history, web forensics

**Cryptographic Analysis:**
- **Hash Calculation**: Generate MD5, SHA1, SHA256, SHA512 hashes
- **Base64 Encoding/Decoding**: Handle encoded communications and data
- Use for: File integrity verification, malware analysis, encoded message analysis

**Network Intelligence:**
- **IP Analysis**: Classify private/public IPs, perform reverse DNS lookups
- **Social Media Scanning**: Check username availability across major platforms
- Use for: Infrastructure mapping, social media reconnaissance, identity correlation

### MCP Tool Proxy

**Access**: Available as tools in chat or directly at <http://localhost:8002/docs>

**Time & Date Tools:**
- Current time and date information
- Timezone conversions and calculations
- Use for: Timeline analysis, coordinating across time zones

**File System Tools** (when enabled):
- Safe file operations and analysis
- Use for: Document processing, file forensics

**Extensible Framework:**
- Add any MCP-compatible tool server
- Configure via `MCP_SERVER_CMD` environment variable

### Using Tools in Investigations

**During a chat, enable tools by:**
1. Starting a new conversation
2. Enabling "Tools" in the chat interface  
3. Ask questions that trigger tool usage:
   - "Check the WHOIS information for example.com"
   - "Analyze this URL for suspicious patterns: https://suspicious-link.com"
   - "Calculate the SHA256 hash of this text: [suspicious content]"
   - "Check if the username 'suspect123' exists on social media platforms"

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

## 🤝 OSINT Community Integration

### Sharing Configurations
- Export search engine configurations
- Share custom engine definitions
- Collaborate on investigation methodologies

### Tool Integration
- API endpoints for external OSINT tools
- Export search results in various formats
- Integration with evidence management systems
