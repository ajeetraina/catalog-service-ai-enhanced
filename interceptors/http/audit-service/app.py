from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
from typing import Dict, Any, List, Optional
import json
import logging
import asyncio
from datetime import datetime
import os
import re
import hashlib

# Configuration
AUDIT_MODE = os.getenv('AUDIT_MODE', 'full')
COMPLIANCE_RULES = os.getenv('COMPLIANCE_RULES', 'pii_detection,sensitive_data').split(',')

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="MCP Audit Interceptor",
    description="Compliance and audit logging for MCP responses",
    version="1.0.0"
)

class ResponseData(BaseModel):
    jsonrpc: str = "2.0"
    id: str
    result: Optional[Dict[str, Any]] = None
    error: Optional[Dict[str, Any]] = None
    meta: Optional[Dict[str, Any]] = {}

class AuditResponse(BaseModel):
    processed: bool
    message: str
    pii_detected: bool = False
    sensitive_count: int = 0
    compliance_score: float = Field(ge=0.0, le=1.0)
    anonymized_response: Optional[Dict[str, Any]] = None

class ComplianceAnalyzer:
    def __init__(self):
        # Custom sensitive patterns
        self.sensitive_patterns = {
            'api_key': re.compile(r'(?i)(api[_-]?key|apikey)\s*[:=]\s*([a-zA-Z0-9_-]+)', re.IGNORECASE),
            'token': re.compile(r'(?i)(token|bearer)\s*[:=]?\s*([a-zA-Z0-9._-]+)', re.IGNORECASE),
            'password': re.compile(r'(?i)(password|pwd|pass)\s*[:=]\s*([^\s]+)', re.IGNORECASE),
            'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
            'phone': re.compile(r'\b(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b'),
        }
    
    async def analyze_response(self, response_data: ResponseData) -> AuditResponse:
        try:
            # Extract content for analysis
            content = self._extract_content(response_data)
            if not content:
                return AuditResponse(
                    processed=True,
                    message="No content to analyze",
                    compliance_score=1.0
                )
            
            # Custom sensitive data detection
            sensitive_matches = []
            for pattern_name, pattern in self.sensitive_patterns.items():
                matches = pattern.findall(content)
                if matches:
                    sensitive_matches.extend([(pattern_name, match) for match in matches])
            
            # Calculate compliance score
            total_violations = len(sensitive_matches)
            content_length = len(content)
            violation_density = total_violations / max(content_length, 1) * 1000
            compliance_score = max(0.0, 1.0 - (violation_density * 0.1))
            
            # Log audit information
            await self._log_audit_event(response_data, sensitive_matches, compliance_score)
            
            return AuditResponse(
                processed=True,
                message=f"Compliance analysis complete: {total_violations} violations detected",
                pii_detected=total_violations > 0,
                sensitive_count=total_violations,
                compliance_score=compliance_score
            )
            
        except Exception as e:
            logger.error(f"Compliance analysis failed: {e}")
            return AuditResponse(
                processed=False,
                message=f"Analysis error: {str(e)}",
                compliance_score=0.0
            )
    
    def _extract_content(self, response_data: ResponseData) -> str:
        if not response_data.result:
            return ""
            
        content_list = response_data.result.get('content', [])
        if not content_list:
            return ""
            
        # Combine all text content
        full_content = ""
        for item in content_list:
            if item.get('type') == 'text' and 'text' in item:
                full_content += item['text'] + "\n"
                
        return full_content.strip()
    
    async def _log_audit_event(self, response_data: ResponseData, sensitive_matches: List, compliance_score: float):
        if AUDIT_MODE == 'errors_only' and compliance_score > 0.8:
            return
            
        audit_record = {
            'timestamp': datetime.utcnow(),
            'session_id': response_data.meta.get('sessionId', 'unknown'),
            'tool_name': response_data.result.get('toolName') if response_data.result else 'error',
            'is_error': response_data.error is not None,
            'sensitive_count': len(sensitive_matches),
            'compliance_score': compliance_score,
            'sensitive_types': [match[0] for match in sensitive_matches],
            'response_id': response_data.id,
            'content_length': len(self._extract_content(response_data)),
        }
        
        # Log to file (in production, this would write to database)
        logger.info(f"AUDIT LOG: {json.dumps(audit_record, default=str)}")

# Global instances
compliance_analyzer = ComplianceAnalyzer()

@app.post("/log", response_model=AuditResponse)
async def log_response(response: ResponseData):
    """Main audit logging endpoint for AFTER interceptor"""
    
    try:
        # Perform compliance analysis
        audit_result = await compliance_analyzer.analyze_response(response)
        
        # Log summary
        if audit_result.sensitive_count > 0:
            logger.warning(f"Sensitive data detected: {audit_result.sensitive_count} violations, score: {audit_result.compliance_score:.2f}")
        else:
            logger.info(f"Clean response: compliance score {audit_result.compliance_score:.2f}")
            
        return audit_result
        
    except Exception as e:
        logger.error(f"Audit processing failed: {e}")
        return AuditResponse(
            processed=False,
            message=f"Audit error: {str(e)}",
            compliance_score=0.0
        )

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "audit_mode": AUDIT_MODE,
        "compliance_rules": COMPLIANCE_RULES,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/metrics")
async def get_metrics():
    return {
        "audit_mode": AUDIT_MODE,
        "compliance_rules_count": len(COMPLIANCE_RULES),
        "sensitive_patterns_count": len(compliance_analyzer.sensitive_patterns),
    }

@app.on_event("startup")
async def startup_event():
    logger.info(f"Audit Interceptor started - Mode: {AUDIT_MODE}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8080, log_level="info")
