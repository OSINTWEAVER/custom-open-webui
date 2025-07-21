#!/usr/bin/env python3
"""
OSINT Tools API Server
A FastAPI-based OpenAPI server providing OSINT investigation tools
"""

import os
import json
import base64
import hashlib
import urllib.parse
import ipaddress
from datetime import datetime, timezone
from typing import Dict, List, Optional, Union
from urllib.parse import urlparse

import requests
import whois
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
import dns.resolver

app = FastAPI(
    title="OSINT Tools API",
    description="OpenAPI server providing OSINT investigation tools for Open WebUI",
    version="1.0.0",
    servers=[{"url": "http://localhost:8001", "description": "Local development server"}]
)

# Models for request/response
class DomainInfo(BaseModel):
    domain: str
    registrar: Optional[str] = None
    creation_date: Optional[str] = None
    expiration_date: Optional[str] = None
    name_servers: List[str] = []
    status: List[str] = []

class DNSRecord(BaseModel):
    type: str
    value: str
    ttl: Optional[int] = None

class URLAnalysis(BaseModel):
    url: str
    domain: str
    subdomain: Optional[str] = None
    path: str
    query_params: Dict[str, str] = {}
    is_suspicious: bool = False
    risk_indicators: List[str] = []

class HashAnalysis(BaseModel):
    input_text: str
    md5: str
    sha1: str
    sha256: str
    sha512: str

class IPInfo(BaseModel):
    ip: str
    is_private: bool
    is_multicast: bool
    is_reserved: bool
    version: int
    reverse_dns: Optional[str] = None

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}

# Domain analysis tools
@app.get("/tools/domain/whois", response_model=DomainInfo)
async def get_domain_whois(
    domain: str = Query(..., description="Domain name to lookup", example="example.com")
):
    """
    Get WHOIS information for a domain
    
    Performs a WHOIS lookup to retrieve domain registration information
    including registrar, creation date, expiration date, and name servers.
    """
    try:
        # Clean domain input
        domain = domain.lower().strip()
        if domain.startswith(('http://', 'https://')):
            domain = urlparse(domain).netloc
        
        w = whois.whois(domain)
        
        # Handle different whois response formats
        creation_date = None
        expiration_date = None
        
        if hasattr(w, 'creation_date') and w.creation_date:
            if isinstance(w.creation_date, list):
                creation_date = w.creation_date[0].isoformat() if w.creation_date[0] else None
            else:
                creation_date = w.creation_date.isoformat() if w.creation_date else None
                
        if hasattr(w, 'expiration_date') and w.expiration_date:
            if isinstance(w.expiration_date, list):
                expiration_date = w.expiration_date[0].isoformat() if w.expiration_date[0] else None
            else:
                expiration_date = w.expiration_date.isoformat() if w.expiration_date else None
        
        name_servers = []
        if hasattr(w, 'name_servers') and w.name_servers:
            name_servers = [ns.lower() for ns in w.name_servers if ns]
            
        status = []
        if hasattr(w, 'status') and w.status:
            if isinstance(w.status, list):
                status = w.status
            else:
                status = [w.status]
        
        return DomainInfo(
            domain=domain,
            registrar=w.registrar if hasattr(w, 'registrar') else None,
            creation_date=creation_date,
            expiration_date=expiration_date,
            name_servers=name_servers,
            status=status
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"WHOIS lookup failed: {str(e)}")

@app.get("/tools/domain/dns", response_model=List[DNSRecord])
async def get_dns_records(
    domain: str = Query(..., description="Domain name to lookup", example="example.com"),
    record_type: str = Query("A", description="DNS record type", example="A")
):
    """
    Get DNS records for a domain
    
    Retrieves DNS records of the specified type for the given domain.
    Common types: A, AAAA, MX, NS, TXT, CNAME, SOA
    """
    try:
        domain = domain.lower().strip()
        record_type = record_type.upper()
        
        resolver = dns.resolver.Resolver()
        resolver.timeout = 10
        resolver.lifetime = 10
        
        answers = resolver.resolve(domain, record_type)
        
        records = []
        for rdata in answers:
            records.append(DNSRecord(
                type=record_type,
                value=str(rdata),
                ttl=answers.ttl
            ))
            
        return records
        
    except dns.resolver.NXDOMAIN:
        raise HTTPException(status_code=404, detail=f"Domain {domain} not found")
    except dns.resolver.NoAnswer:
        raise HTTPException(status_code=404, detail=f"No {record_type} records found for {domain}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"DNS lookup failed: {str(e)}")

# URL analysis tools
@app.get("/tools/url/analyze", response_model=URLAnalysis)
async def analyze_url(
    url: str = Query(..., description="URL to analyze", example="https://example.com/path?param=value")
):
    """
    Analyze URL structure and detect suspicious patterns
    
    Parses the URL and checks for common indicators of malicious or suspicious URLs
    including suspicious TLDs, URL shorteners, suspicious patterns, etc.
    """
    try:
        parsed = urlparse(url)
        
        if not parsed.netloc:
            raise HTTPException(status_code=400, detail="Invalid URL format")
        
        # Extract domain parts
        domain_parts = parsed.netloc.split('.')
        domain = '.'.join(domain_parts[-2:]) if len(domain_parts) >= 2 else parsed.netloc
        subdomain = '.'.join(domain_parts[:-2]) if len(domain_parts) > 2 else None
        
        # Parse query parameters
        query_params = {}
        if parsed.query:
            query_params = dict(urllib.parse.parse_qsl(parsed.query))
        
        # Check for suspicious indicators
        risk_indicators = []
        is_suspicious = False
        
        # Suspicious TLDs
        suspicious_tlds = ['.tk', '.ml', '.ga', '.cf', '.bit', '.onion']
        if any(domain.endswith(tld) for tld in suspicious_tlds):
            risk_indicators.append("Suspicious TLD")
            is_suspicious = True
        
        # URL shorteners
        shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'short.link']
        if any(shortener in domain for shortener in shorteners):
            risk_indicators.append("URL shortener detected")
        
        # Suspicious patterns
        if len(parsed.netloc) > 60:
            risk_indicators.append("Unusually long domain name")
            is_suspicious = True
            
        if parsed.netloc.count('-') > 3:
            risk_indicators.append("Excessive hyphens in domain")
            is_suspicious = True
            
        # Check for IP address instead of domain
        try:
            ipaddress.ip_address(parsed.netloc)
            risk_indicators.append("IP address instead of domain name")
            is_suspicious = True
        except ValueError:
            pass
        
        return URLAnalysis(
            url=url,
            domain=domain,
            subdomain=subdomain,
            path=parsed.path,
            query_params=query_params,
            is_suspicious=is_suspicious,
            risk_indicators=risk_indicators
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"URL analysis failed: {str(e)}")

# Cryptographic tools
@app.get("/tools/crypto/hash", response_model=HashAnalysis)
async def calculate_hashes(
    text: str = Query(..., description="Text to hash", example="Hello World")
):
    """
    Calculate multiple hash values for input text
    
    Generates MD5, SHA1, SHA256, and SHA512 hashes for the given input text.
    Useful for file integrity verification and malware analysis.
    """
    try:
        text_bytes = text.encode('utf-8')
        
        md5_hash = hashlib.md5(text_bytes).hexdigest()
        sha1_hash = hashlib.sha1(text_bytes).hexdigest()
        sha256_hash = hashlib.sha256(text_bytes).hexdigest()
        sha512_hash = hashlib.sha512(text_bytes).hexdigest()
        
        return HashAnalysis(
            input_text=text,
            md5=md5_hash,
            sha1=sha1_hash,
            sha256=sha256_hash,
            sha512=sha512_hash
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Hash calculation failed: {str(e)}")

@app.get("/tools/crypto/base64_decode")
async def decode_base64(
    encoded_text: str = Query(..., description="Base64 encoded text to decode", example="SGVsbG8gV29ybGQ=")
):
    """
    Decode Base64 encoded text
    
    Decodes Base64 encoded strings, commonly found in malware analysis
    and encoded communications.
    """
    try:
        decoded_bytes = base64.b64decode(encoded_text)
        decoded_text = decoded_bytes.decode('utf-8')
        
        return {
            "encoded": encoded_text,
            "decoded": decoded_text,
            "decoded_bytes_length": len(decoded_bytes)
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Base64 decoding failed: {str(e)}")

@app.get("/tools/crypto/base64_encode")
async def encode_base64(
    plain_text: str = Query(..., description="Plain text to encode", example="Hello World")
):
    """
    Encode text to Base64
    
    Encodes plain text to Base64 format.
    """
    try:
        encoded_bytes = base64.b64encode(plain_text.encode('utf-8'))
        encoded_text = encoded_bytes.decode('ascii')
        
        return {
            "plain_text": plain_text,
            "encoded": encoded_text,
            "original_bytes_length": len(plain_text.encode('utf-8'))
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Base64 encoding failed: {str(e)}")

# IP analysis tools
@app.get("/tools/ip/analyze", response_model=IPInfo)
async def analyze_ip(
    ip: str = Query(..., description="IP address to analyze", example="8.8.8.8")
):
    """
    Analyze IP address properties
    
    Determines if an IP address is private, multicast, reserved, and attempts
    reverse DNS lookup.
    """
    try:
        ip_obj = ipaddress.ip_address(ip)
        
        # Attempt reverse DNS lookup
        reverse_dns = None
        try:
            import socket
            reverse_dns = socket.gethostbyaddr(ip)[0]
        except (socket.herror, socket.gaierror):
            pass
        
        return IPInfo(
            ip=str(ip_obj),
            is_private=ip_obj.is_private,
            is_multicast=ip_obj.is_multicast,
            is_reserved=ip_obj.is_reserved,
            version=ip_obj.version,
            reverse_dns=reverse_dns
        )
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid IP address format")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"IP analysis failed: {str(e)}")

# OSINT utilities
@app.get("/tools/osint/social_media_usernames")
async def check_social_media_username(
    username: str = Query(..., description="Username to check", example="johndoe")
):
    """
    Check username availability across major social media platforms
    
    Attempts to determine if a username exists on various social media platforms
    by checking for HTTP response codes (simplified check).
    """
    platforms = {
        "twitter": f"https://twitter.com/{username}",
        "instagram": f"https://instagram.com/{username}",
        "github": f"https://github.com/{username}",
        "reddit": f"https://reddit.com/user/{username}",
        "linkedin": f"https://linkedin.com/in/{username}",
        "youtube": f"https://youtube.com/@{username}",
        "tiktok": f"https://tiktok.com/@{username}",
        "facebook": f"https://facebook.com/{username}"
    }
    
    results = {}
    
    for platform, url in platforms.items():
        try:
            response = requests.head(url, timeout=5, allow_redirects=True)
            results[platform] = {
                "url": url,
                "status_code": response.status_code,
                "likely_exists": response.status_code == 200
            }
        except requests.RequestException:
            results[platform] = {
                "url": url,
                "status_code": None,
                "likely_exists": False,
                "error": "Request failed"
            }
    
    return {
        "username": username,
        "platforms": results,
        "summary": {
            "total_platforms": len(platforms),
            "likely_exists_count": sum(1 for r in results.values() if r.get("likely_exists", False))
        }
    }

@app.get("/tools/osint/wayback_check")
async def check_wayback_machine(
    url: str = Query(..., description="URL to check in Wayback Machine", example="https://example.com")
):
    """
    Check if URL has archived versions in Wayback Machine
    
    Queries the Wayback Machine API to see if the URL has been archived
    and returns basic information about available snapshots.
    """
    try:
        # Wayback Machine availability API
        api_url = f"http://archive.org/wayback/available?url={urllib.parse.quote(url)}"
        
        response = requests.get(api_url, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("archived_snapshots", {}).get("closest"):
            snapshot = data["archived_snapshots"]["closest"]
            return {
                "url": url,
                "is_archived": True,
                "closest_snapshot": {
                    "wayback_url": snapshot.get("url"),
                    "timestamp": snapshot.get("timestamp"),
                    "status": snapshot.get("status")
                },
                "wayback_search_url": f"https://web.archive.org/web/*/{url}"
            }
        else:
            return {
                "url": url,
                "is_archived": False,
                "closest_snapshot": None,
                "wayback_search_url": f"https://web.archive.org/web/*/{url}"
            }
            
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Wayback Machine check failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
