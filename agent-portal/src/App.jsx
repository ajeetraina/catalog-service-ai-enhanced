import { useState } from 'react'
import axios from 'axios'

function App() {
  const [formData, setFormData] = useState({
    vendorName: '',
    productName: '',
    description: '',
    price: '',
    category: ''
  })
  const [evaluation, setEvaluation] = useState(null)
  const [loading, setLoading] = useState(false)
  const [catalogStatus, setCatalogStatus] = useState(null) // 'adding', 'success', 'failed'
  const [error, setError] = useState(null)
  
  // Configuration - you can adjust these thresholds
  const ACCEPTANCE_THRESHOLD = 70
  const API_BASE_URL = process.env.API_URL || 'http://localhost:3000'
  const AGENT_SERVICE_URL = process.env.AGENT_SERVICE_URL || 'http://localhost:7777'
  
  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setEvaluation(null)
    setCatalogStatus(null)
    
    try {
      console.log('🤖 Submitting to AI Agent for evaluation...')
      
      // Step 1: Submit to AI Evaluation Agent
      const evalResponse = await axios.post(
        `${AGENT_SERVICE_URL}/products/evaluate`,
        {
          vendorName: formData.vendorName,
          productName: formData.productName,
          description: formData.description,
          price: formData.price,
          category: formData.category
        },
        {
          timeout: 30000, // 30 second timeout for AI processing
          headers: {
            'Content-Type': 'application/json'
          }
        }
      )
      
      console.log('✅ AI Evaluation Response:', evalResponse.data)
      setEvaluation(evalResponse.data.evaluation)
      
      // Step 2: Check if product meets acceptance criteria
      const aiScore = evalResponse.data.evaluation.score
      const isApproved = aiScore >= ACCEPTANCE_THRESHOLD
      
      if (isApproved) {
        console.log(`🎉 Product approved with score ${aiScore}! Adding to catalog...`)
        setCatalogStatus('adding')
        
        // Step 3: Add approved product to main catalog
        const productData = {
          name: formData.productName,
          description: formData.description,
          price: parseFloat(formData.price),
          vendor: formData.vendorName,
          category: formData.category,
          ai_evaluation: {
            score: aiScore,
            decision: evalResponse.data.evaluation.decision,
            evaluated_at: new Date().toISOString()
          }
        }
        
        const catalogResponse = await axios.post(
          `${API_BASE_URL}/api/products`,
          productData,
          {
            timeout: 10000,
            headers: {
              'Content-Type': 'application/json'
            }
          }
        )
        
        if (catalogResponse.data.success) {
          console.log('✅ Product successfully added to catalog!')
          setCatalogStatus('success')
        } else {
          throw new Error('Failed to add product to catalog')
        }
        
      } else {
        console.log(`❌ Product rejected with score ${aiScore} (threshold: ${ACCEPTANCE_THRESHOLD})`)
        setCatalogStatus('rejected')
      }
      
    } catch (error) {
      console.error('❌ Error in submission process:', error)
      
      // Provide user-friendly error messages
      if (error.code === 'ECONNREFUSED') {
        setError('Unable to connect to AI service. Please ensure all services are running.')
      } else if (error.response?.status === 404) {
        setError('AI evaluation endpoint not found. Please check service configuration.')
      } else if (error.response?.status === 500) {
        setError('AI service error. Please try again or contact support.')
      } else if (catalogStatus === 'adding') {
        setError('Product was approved by AI but failed to add to catalog. Please try again.')
        setCatalogStatus('failed')
      } else {
        setError(error.message || 'An unexpected error occurred')
      }
    } finally {
      setLoading(false)
    }
  }
  
  const resetForm = () => {
    setFormData({
      vendorName: '',
      productName: '',
      description: '',
      price: '',
      category: ''
    })
    setEvaluation(null)
    setCatalogStatus(null)
    setError(null)
  }
  
  const getStatusColor = (score) => {
    if (score >= 80) return '#28a745' // Green
    if (score >= ACCEPTANCE_THRESHOLD) return '#ffc107' // Yellow
    return '#dc3545' // Red
  }
  
  return (
    <div style={{ maxWidth: '700px', margin: '0 auto', padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      {/* Header */}
      <div style={{ textAlign: 'center', marginBottom: '30px' }}>
        <h1 style={{ color: '#333', marginBottom: '10px' }}>🤖 AI-Enhanced Vendor Portal</h1>
        <p style={{ color: '#666', fontSize: '16px' }}>
          Submit products for AI evaluation and automatic catalog integration
        </p>
      </div>
      
      {/* Error Display */}
      {error && (
        <div style={{
          backgroundColor: '#f8d7da',
          border: '1px solid #f5c6cb',
          color: '#721c24',
          padding: '15px',
          borderRadius: '4px',
          marginBottom: '20px'
        }}>
          <strong>Error:</strong> {error}
        </div>
      )}
      
      {/* Submission Form */}
      <div style={{
        border: '1px solid #ddd',
        borderRadius: '8px',
        padding: '25px',
        backgroundColor: '#f8f9fa',
        marginBottom: '30px'
      }}>
        <h2 style={{ marginTop: '0', color: '#333', marginBottom: '20px' }}>Product Submission</h2>
        
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginBottom: '15px' }}>
            <div>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#555' }}>
                Vendor Name *
              </label>
              <input
                type="text"
                placeholder="e.g., TechCorp"
                value={formData.vendorName}
                onChange={(e) => setFormData({...formData, vendorName: e.target.value})}
                required
                style={{
                  width: '100%',
                  padding: '12px',
                  borderRadius: '4px',
                  border: '1px solid #ddd',
                  fontSize: '14px'
                }}
              />
            </div>
            
            <div>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#555' }}>
                Category
              </label>
              <input
                type="text"
                placeholder="e.g., Electronics"
                value={formData.category}
                onChange={(e) => setFormData({...formData, category: e.target.value})}
                style={{
                  width: '100%',
                  padding: '12px',
                  borderRadius: '4px',
                  border: '1px solid #ddd',
                  fontSize: '14px'
                }}
              />
            </div>
          </div>
          
          <div style={{ marginBottom: '15px' }}>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#555' }}>
              Product Name *
            </label>
            <input
              type="text"
              placeholder="e.g., Smart Watch Ultra"
              value={formData.productName}
              onChange={(e) => setFormData({...formData, productName: e.target.value})}
              required
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '4px',
                border: '1px solid #ddd',
                fontSize: '14px'
              }}
            />
          </div>
          
          <div style={{ marginBottom: '15px' }}>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#555' }}>
              Product Description *
            </label>
            <textarea
              placeholder="Detailed description of your product features and benefits..."
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              required
              rows={4}
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '4px',
                border: '1px solid #ddd',
                fontSize: '14px',
                resize: 'vertical'
              }}
            />
          </div>
          
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold', color: '#555' }}>
              Price (USD) *
            </label>
            <input
              type="number"
              step="0.01"
              min="0"
              placeholder="299.99"
              value={formData.price}
              onChange={(e) => setFormData({...formData, price: e.target.value})}
              required
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '4px',
                border: '1px solid #ddd',
                fontSize: '14px'
              }}
            />
          </div>
          
          <button 
            type="submit" 
            disabled={loading}
            style={{ 
              backgroundColor: loading ? '#6c757d' : '#007bff', 
              color: 'white', 
              padding: '15px 30px', 
              border: 'none', 
              borderRadius: '4px', 
              cursor: loading ? 'not-allowed' : 'pointer',
              fontSize: '16px',
              width: '100%',
              fontWeight: 'bold'
            }}
          >
            {loading ? '🤖 AI Analyzing Product...' : '🚀 Submit for AI Evaluation'}
          </button>
        </form>
      </div>
      
      {/* AI Evaluation Results */}
      {evaluation && (
        <div style={{ 
          border: '1px solid #ddd', 
          borderRadius: '8px', 
          padding: '25px', 
          backgroundColor: '#ffffff',
          boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ marginTop: '0', color: '#333', marginBottom: '20px' }}>
            🤖 AI Evaluation Results
          </h2>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '20px', marginBottom: '20px' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{
                fontSize: '48px',
                fontWeight: 'bold',
                color: getStatusColor(evaluation.score),
                marginBottom: '10px'
              }}>
                {evaluation.score}/100
              </div>
              <div style={{ fontSize: '14px', color: '#666' }}>AI Quality Score</div>
            </div>
            
            <div>
              <div style={{ marginBottom: '10px' }}>
                <strong>Decision:</strong> {evaluation.decision}
              </div>
              <div style={{ marginBottom: '10px' }}>
                <strong>Status:</strong> {evaluation.score >= ACCEPTANCE_THRESHOLD ? '✅ Approved' : '❌ Rejected'}
              </div>
              <div style={{ fontSize: '14px', color: '#666' }}>
                Minimum score for acceptance: {ACCEPTANCE_THRESHOLD}/100
              </div>
            </div>
          </div>
          
          {/* Catalog Integration Status */}
          {catalogStatus && (
            <div style={{
              marginTop: '20px',
              padding: '15px',
              borderRadius: '4px',
              backgroundColor: 
                catalogStatus === 'success' ? '#d4edda' :
                catalogStatus === 'adding' ? '#fff3cd' :
                catalogStatus === 'rejected' ? '#f8d7da' :
                '#f8d7da', // failed
              border: '1px solid ' +
                (catalogStatus === 'success' ? '#c3e6cb' :
                catalogStatus === 'adding' ? '#ffeaa7' :
                catalogStatus === 'rejected' ? '#f5c6cb' :
                '#f5c6cb'), // failed
              color:
                catalogStatus === 'success' ? '#155724' :
                catalogStatus === 'adding' ? '#856404' :
                '#721c24'
            }}>
              {catalogStatus === 'adding' && (
                <div>⏳ Adding approved product to catalog...</div>
              )}
              {catalogStatus === 'success' && (
                <div>
                  <strong>🎉 Success!</strong> Product has been added to the main catalog and is now available for customers.
                </div>
              )}
              {catalogStatus === 'rejected' && (
                <div>
                  <strong>📋 Not Added:</strong> Product did not meet minimum quality standards (score below {ACCEPTANCE_THRESHOLD}) and was not added to catalog.
                </div>
              )}
              {catalogStatus === 'failed' && (
                <div>
                  <strong>⚠️ Integration Failed:</strong> Product was approved by AI but failed to add to catalog. Please try again.
                </div>
              )}
            </div>
          )}
          
          {/* Action Buttons */}
          <div style={{ marginTop: '25px', textAlign: 'center' }}>
            <button 
              onClick={resetForm}
              style={{ 
                backgroundColor: '#6c757d', 
                color: 'white', 
                padding: '12px 25px', 
                border: 'none', 
                borderRadius: '4px', 
                cursor: 'pointer',
                fontSize: '14px',
                marginRight: '10px'
              }}
            >
              📝 Submit Another Product
            </button>
            
            <a 
              href="http://localhost:5173" 
              target="_blank" 
              rel="noopener noreferrer"
              style={{
                backgroundColor: '#28a745',
                color: 'white',
                padding: '12px 25px',
                textDecoration: 'none',
                borderRadius: '4px',
                fontSize: '14px'
              }}
            >
              👀 View Catalog
            </a>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
