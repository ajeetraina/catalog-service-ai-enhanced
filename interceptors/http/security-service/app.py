from fastapi import FastAPI, HTTPException, Request, Response
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
import json
import re
import logging
import time
from datetime import datetime, timedelta
import httpx
import asyncio
import os
from collections import defaultdict, deque

# Security configuration from environment
SECURITY_MODE = os.getenv('SECURITY_MODE', 'strict')  # strict, moderate, permissive
MAX_QUERY_LENGTH = int(os.getenv('MAX_QUERY_LENGTH', '500'))
RATE_LIMIT_RPM = int(os.getenv('RATE_LIMIT_RPM', '60'))
BLOCKED_PATTERNS = os.getenv('BLOCKED_PATTERNS', 'password,secret,token,api_key').split(',')
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')

# Logging setup
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="MCP Security Interceptor",
    description="Advanced security validation for MCP tool calls",
    version="1.0.0"
)

class ToolCallRequest(BaseModel):
    jsonrpc: str = "2.0"
    id: str
    method: str
    params: Dict[str, Any]
    meta: Optional[Dict[str, Any]] = {}

class SecurityResponse(BaseModel):
    allowed: bool
    message: str
    risk_score: float = Field(ge=0.0, le=1.0)
    blocked_reasons: List[str] = []
    enhanced_request: Optional[Dict[str, Any]] = None

class SecurityAnalyzer:
    def __init__(self):
        # Compile regex patterns for better performance
        self.malicious_patterns = [
            re.compile(r'(?i)sql\s*injection', re.IGNORECASE),
            re.compile(r'(?i)drop\s+table', re.IGNORECASE),
            re.compile(r'(?i)union\s+select', re.IGNORECASE),
            re.compile(r'(?i)<script[^>]*>', re.IGNORECASE),
            re.compile(r'(?i)javascript:', re.IGNORECASE),
            re.compile(r'(?i)eval\s*\(', re.IGNORECASE),
        ]
        
        self.sensitive_patterns = [
            re.compile(r'(?i)(password|pwd)\s*[:=]\s*\S+', re.IGNORECASE),
            re.compile(r'(?i)(api[_-]?key|apikey)\s*[:=]\s*\S+', re.IGNORECASE),
            re.compile(r'(?i)(secret|token)\s*[:=]\s*\S+', re.IGNORECASE),
        ]
        
        # Rate limiting storage (in production, use Redis)
        self.rate_limits = defaultdict(lambda: deque())
        
    def analyze_request(self, request: ToolCallRequest) -> SecurityResponse:
        risk_score = 0.0
        blocked_reasons = []
        
        # Extract key data
        session_id = request.meta.get('sessionId', 'anonymous')
        tool_name = request.params.get('name', 'unknown')
        query = request.params.get('arguments', {}).get('query', '')
        
        logger.info(f"Analyzing request: session={session_id}, tool={tool_name}, query_len={len(query)}")
        
        # 1. Query length validation
        if len(query) > MAX_QUERY_LENGTH:
            risk_score += 0.3
            blocked_reasons.append(f"Query too long ({len(query)} > {MAX_QUERY_LENGTH} chars)")
            
        # 2. Malicious pattern detection
        for pattern in self.malicious_patterns:
            if pattern.search(query):
                risk_score += 0.8
                blocked_reasons.append(f"Malicious pattern detected: {pattern.pattern}")
                
        # 3. Sensitive data exposure check
        for pattern in self.sensitive_patterns:
            if pattern.search(query):
                risk_score += 0.6
                blocked_reasons.append(f"Sensitive data in query: {pattern.pattern}")
                
        # 4. Rate limiting check
        rate_limit_exceeded = self._check_rate_limit(session_id)
        if rate_limit_exceeded:
            risk_score += 0.5
            blocked_reasons.append(f"Rate limit exceeded ({RATE_LIMIT_RPM} RPM)")
            
        # Determine if request should be blocked
        risk_threshold = {'strict': 0.3, 'moderate': 0.5, 'permissive': 0.8}
        threshold = risk_threshold.get(SECURITY_MODE, 0.3)
        
        allowed = risk_score < threshold
        
        if not allowed:
            logger.warning(f"BLOCKED: session={session_id}, risk_score={risk_score:.2f}, reasons={blocked_reasons}")
        else:
            logger.info(f"ALLOWED: session={session_id}, risk_score={risk_score:.2f}")
            
        return SecurityResponse(
            allowed=allowed,
            message="Request analysis complete",
            risk_score=min(risk_score, 1.0),
            blocked_reasons=blocked_reasons,
            enhanced_request=self._enhance_request(request) if allowed else None
        )
        
    def _check_rate_limit(self, session_id: str) -> bool:
        now = time.time()
        window_start = now - 60  # 60 second window
        
        # Clean old entries
        session_requests = self.rate_limits[session_id]
        while session_requests and session_requests[0] < window_start:
            session_requests.popleft()
            
        # Check limit
        if len(session_requests) >= RATE_LIMIT_RPM:
            return True
            
        # Add current request
        session_requests.append(now)
        return False
        
    def _enhance_request(self, request: ToolCallRequest) -> Dict[str, Any]:
        enhanced = request.dict()
        
        # Add security metadata
        enhanced['meta'] = enhanced.get('meta', {})
        enhanced['meta']['security_checked'] = True
        enhanced['meta']['security_timestamp'] = datetime.utcnow().isoformat()
        enhanced['meta']['security_mode'] = SECURITY_MODE
        
        return enhanced

# Global instances
security_analyzer = SecurityAnalyzer()

@app.post("/validate", response_model=SecurityResponse)
async def validate_request(request: ToolCallRequest):
    """Main security validation endpoint for BEFORE interceptor"""
    
    try:
        # Basic security analysis
        security_result = security_analyzer.analyze_request(request)
        return security_result
        
    except Exception as e:
        logger.error(f"Security validation failed: {e}")
        return SecurityResponse(
            allowed=False,
            message=f"Security validation error: {str(e)}",
            risk_score=1.0,
            blocked_reasons=["Internal security error"]
        )

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "security_mode": SECURITY_MODE,
        "rate_limit_rpm": RATE_LIMIT_RPM,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/metrics")
async def get_metrics():
    """Security metrics endpoint"""
    return {
        "active_sessions": len(security_analyzer.rate_limits),
        "security_mode": SECURITY_MODE,
        "blocked_patterns_count": len(BLOCKED_PATTERNS),
        "malicious_patterns_count": len(security_analyzer.malicious_patterns),
    }

@app.on_event("startup")
async def startup_event():
    """Application startup"""
    logger.info(f"Security Interceptor started - Mode: {SECURITY_MODE}, Rate Limit: {RATE_LIMIT_RPM} RPM")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8080,
        log_level=LOG_LEVEL.lower(),
        access_log=True
    )
