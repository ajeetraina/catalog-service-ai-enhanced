import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const SECURITY_SERVICE_URL = process.env.SECURITY_SERVICE_URL || 'http://security-interceptor:8080';
const SECURITY_ENABLED = process.env.MCP_SECURITY_ENABLED === 'true';

class SecurityMiddleware {
  constructor() {
    this.enabled = SECURITY_ENABLED;
    console.log(`🛡️  Security Middleware: ${this.enabled ? 'ENABLED' : 'DISABLED'}`);
  }

  async validateRequest(req, res, next) {
    if (!this.enabled) {
      console.log('⚠️  Security middleware disabled, skipping validation');
      return next();
    }

    try {
      const requestData = {
        jsonrpc: "2.0",
        id: `agent-${Date.now()}`,
        method: "tools/call",
        params: {
          name: "product_evaluation",
          arguments: req.body
        },
        meta: {
          sessionId: req.headers['x-session-id'] || req.ip || 'anonymous',
          userAgent: req.headers['user-agent'],
          timestamp: new Date().toISOString()
        }
      };

      console.log(`🔍 Validating request for session: ${requestData.meta.sessionId}`);

      const validationResponse = await axios.post(
        `${SECURITY_SERVICE_URL}/validate`,
        requestData,
        {
          timeout: 5000,
          headers: { 'Content-Type': 'application/json' }
        }
      );

      const { allowed, risk_score, blocked_reasons, message } = validationResponse.data;

      if (!allowed) {
        console.log(`🚫 Request BLOCKED: Risk score ${risk_score}, Reasons: ${blocked_reasons.join(', ')}`);
        
        return res.status(403).json({
          success: false,
          error: 'Request blocked by security interceptor',
          details: {
            risk_score,
            blocked_reasons,
            message: message || 'Security validation failed'
          },
          metadata: {
            timestamp: new Date().toISOString(),
            session_id: requestData.meta.sessionId
          }
        });
      }

      console.log(`✅ Request ALLOWED: Risk score ${risk_score}`);
      
      // Add security metadata to request
      req.security = {
        validated: true,
        risk_score,
        session_id: requestData.meta.sessionId
      };

      next();

    } catch (error) {
      console.error('❌ Security validation error:', error.message);
      
      // In strict mode, block on security service failure
      const strictMode = process.env.SECURITY_MODE === 'strict';
      
      if (strictMode) {
        return res.status(503).json({
          success: false,
          error: 'Security service unavailable - request blocked',
          details: {
            message: 'Security validation service is not responding',
            strict_mode: true
          }
        });
      } else {
        console.log('⚠️  Security service down, allowing request in non-strict mode');
        req.security = { validated: false, fallback: true };
        next();
      }
    }
  }

  async logAudit(req, res, result) {
    if (!this.enabled) return;

    try {
      const auditData = {
        timestamp: new Date().toISOString(),
        session_id: req.security?.session_id || 'unknown',
        request: {
          method: req.method,
          path: req.path,
          ip: req.ip,
          user_agent: req.headers['user-agent']
        },
        response: {
          success: result.success,
          score: result.evaluation?.score,
          decision: result.evaluation?.decision
        },
        security: req.security
      };

      // Send to audit service (non-blocking)
      axios.post(
        'http://audit-interceptor:8080/log',
        auditData,
        { timeout: 2000 }
      ).catch(err => {
        console.warn('⚠️  Audit logging failed:', err.message);
      });

    } catch (error) {
      console.warn('⚠️  Audit logging error:', error.message);
    }
  }
}

export default SecurityMiddleware;
