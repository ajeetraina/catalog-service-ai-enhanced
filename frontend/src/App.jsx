import { useState, useEffect } from 'react'
import axios from 'axios'

function App() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
<<<<<<< HEAD
  
=======
  const [showAddForm, setShowAddForm] = useState(false)
  const [formData, setFormData] = useState({
    vendorName: '',
    productName: '',
    description: '',
    price: '',
    category: ''
  })
  const [evaluation, setEvaluation] = useState(null)
  const [evaluating, setEvaluating] = useState(false)
  const [catalogStatus, setCatalogStatus] = useState(null)

  const AGENT_SERVICE_URL = 'http://localhost:7777'
  const BACKEND_API_URL = 'http://localhost:3000'
  const ACCEPTANCE_THRESHOLD = 70

>>>>>>> 6193edd (Added)
  useEffect(() => {
    fetchProducts()
  }, [])

  const fetchProducts = async () => {
    try {
      setLoading(true)
      setError(null)
<<<<<<< HEAD
      const response = await axios.get('http://localhost:3000/api/products')
      // Handle both response formats: direct array or nested in products property
      const productsData = response.data.products || response.data
      setProducts(productsData)
      setProducts(response.data.products)
=======
      const response = await axios.get(`${BACKEND_API_URL}/api/products`)
      const productsData = response.data.products || response.data
      setProducts(productsData)
>>>>>>> 6193edd (Added)
    } catch (error) {
      console.error('Error fetching products:', error)
      setError(`Failed to fetch products: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }

  const handleAIEvaluation = async (e) => {
    e.preventDefault()
    setEvaluating(true)
    setEvaluation(null)
    setCatalogStatus(null)
    setError(null)

    try {
      console.log('Submitting to AI for evaluation...')
      
      // Step 1: AI Evaluation
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
          timeout: 60000,
          headers: { 'Content-Type': 'application/json' }
        }
      )

      const evaluationResult = evalResponse.data.evaluation
      setEvaluation(evaluationResult)
      
      console.log(`AI Evaluation: ${evaluationResult.score}/100 - ${evaluationResult.decision}`)

      // Step 2: Auto-add to catalog if approved
      if (evaluationResult.score >= ACCEPTANCE_THRESHOLD) {
        console.log('Product approved! Adding to catalog...')
        setCatalogStatus('adding')

        const productData = {
          name: formData.productName,
          description: formData.description,
          price: parseFloat(formData.price),
          vendor: formData.vendorName,
          category: formData.category,
          ai_evaluation: {
            score: evaluationResult.score,
            decision: evaluationResult.decision,
            evaluated_at: new Date().toISOString()
          }
        }

        const catalogResponse = await axios.post(
          `${BACKEND_API_URL}/api/products`,
          productData,
          {
            timeout: 10000,
            headers: { 'Content-Type': 'application/json' }
          }
        )

        if (catalogResponse.data.success) {
          console.log('Product added to catalog!')
          setCatalogStatus('success')
          // Refresh products list
          await fetchProducts()
        } else {
          setCatalogStatus('failed')
        }
      } else {
        console.log(`Product rejected with score ${evaluationResult.score}`)
        setCatalogStatus('rejected')
      }

    } catch (error) {
      console.error('Error in AI evaluation:', error)
      if (error.code === 'ECONNREFUSED') {
        setError('AI service unavailable. Please ensure all services are running.')
      } else if (error.response?.status === 404) {
        setError('AI evaluation endpoint not found.')
      } else {
        setError(error.message || 'AI evaluation failed')
      }
    } finally {
      setEvaluating(false)
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
    setShowAddForm(false)
  }

  const getStatusColor = (score) => {
    if (score >= 80) return '#28a745'
    if (score >= ACCEPTANCE_THRESHOLD) return '#ffc107'
    return '#dc3545'
  }

  return (
<<<<<<< HEAD
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1 style={{ color: '#333', marginBottom: '20px' }}>AI-Enhanced Catalog Service</h1>
      <div>
        <h2 style={{ color: '#666', marginBottom: '15px' }}>Products</h2>
        
        {loading && (
          <div style={{ 
            padding: '20px', 
            textAlign: 'center', 
=======
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif', maxWidth: '900px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
        <div>
          <h1 style={{ color: '#333', margin: 0 }}>AI-Enhanced Catalog Service</h1>
          <p style={{ color: '#666', margin: '5px 0 0 0' }}>
            Intelligent product evaluation and catalog management
          </p>
        </div>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          style={{
            backgroundColor: showAddForm ? '#dc3545' : '#007bff',
            color: 'white',
            padding: '12px 20px',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '14px',
            fontWeight: 'bold'
          }}
        >
          {showAddForm ? 'Cancel' : 'Submit Product for AI Evaluation'}
        </button>
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

      {/* AI Product Submission Form */}
      {showAddForm && (
        <div style={{
          border: '1px solid #ddd',
          borderRadius: '8px',
          padding: '25px',
          marginBottom: '30px',
          backgroundColor: '#f8f9fa'
        }}>
          <h2 style={{ marginTop: 0, color: '#333', marginBottom: '20px' }}>
            AI Product Evaluation
          </h2>

          <form onSubmit={handleAIEvaluation}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginBottom: '15px' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
                  Vendor Name *
                </label>
                <input
                  type="text"
                  value={formData.vendorName}
                  onChange={(e) => setFormData({...formData, vendorName: e.target.value})}
                  required
                  placeholder="e.g., TechCorp"
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
                  Category
                </label>
                <input
                  type="text"
                  value={formData.category}
                  onChange={(e) => setFormData({...formData, category: e.target.value})}
                  placeholder="e.g., Electronics"
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px'
                  }}
                />
              </div>
            </div>

            <div style={{ marginBottom: '15px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
                Product Name *
              </label>
              <input
                type="text"
                value={formData.productName}
                onChange={(e) => setFormData({...formData, productName: e.target.value})}
                required
                placeholder="e.g., Smart Fitness Tracker"
                style={{
                  width: '100%',
                  padding: '10px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
              />
            </div>

            <div style={{ marginBottom: '15px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
                Product Description *
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({...formData, description: e.target.value})}
                required
                placeholder="Detailed description of features and benefits..."
                rows={4}
                style={{
                  width: '100%',
                  padding: '10px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px',
                  resize: 'vertical'
                }}
              />
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '5px', fontWeight: 'bold' }}>
                Price (USD) *
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={formData.price}
                onChange={(e) => setFormData({...formData, price: e.target.value})}
                required
                placeholder="299.99"
                style={{
                  width: '200px',
                  padding: '10px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  fontSize: '14px'
                }}
              />
            </div>

            <button
              type="submit"
              disabled={evaluating}
              style={{
                backgroundColor: evaluating ? '#6c757d' : '#007bff',
                color: 'white',
                padding: '15px 30px',
                border: 'none',
                borderRadius: '4px',
                cursor: evaluating ? 'not-allowed' : 'pointer',
                fontSize: '16px',
                fontWeight: 'bold',
                width: '100%'
              }}
            >
              {evaluating ? 'AI Analyzing Product...' : 'Submit for AI Evaluation'}
            </button>
          </form>

          {/* AI Evaluation Results */}
          {evaluation && (
            <div style={{
              marginTop: '25px',
              border: '1px solid #ddd',
              borderRadius: '8px',
              padding: '20px',
              backgroundColor: '#ffffff'
            }}>
              <h3 style={{ marginTop: 0, color: '#333' }}>AI Evaluation Results</h3>

              <div style={{ display: 'flex', alignItems: 'center', marginBottom: '15px' }}>
                <div style={{
                  fontSize: '36px',
                  fontWeight: 'bold',
                  color: getStatusColor(evaluation.score),
                  marginRight: '20px'
                }}>
                  {evaluation.score}/100
                </div>
                <div>
                  <div style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '5px' }}>
                    {evaluation.decision}
                  </div>
                  <div style={{ color: '#666' }}>
                    Threshold: {ACCEPTANCE_THRESHOLD}/100
                  </div>
                </div>
              </div>

              <div style={{ marginBottom: '15px' }}>
                <strong>Reasoning:</strong> {evaluation.reasoning}
              </div>

              {/* Catalog Integration Status */}
              {catalogStatus && (
                <div style={{
                  marginTop: '15px',
                  padding: '15px',
                  borderRadius: '4px',
                  backgroundColor:
                    catalogStatus === 'success' ? '#d4edda' :
                    catalogStatus === 'adding' ? '#fff3cd' :
                    catalogStatus === 'rejected' ? '#f8d7da' :
                    '#f8d7da',
                  border: '1px solid ' + (
                    catalogStatus === 'success' ? '#c3e6cb' :
                    catalogStatus === 'adding' ? '#ffeaa7' :
                    '#f5c6cb'
                  )
                }}>
                  {catalogStatus === 'adding' && 'Adding approved product to catalog...'}
                  {catalogStatus === 'success' && 'Product successfully added to catalog!'}
                  {catalogStatus === 'rejected' && `Product rejected (score below ${ACCEPTANCE_THRESHOLD})`}
                  {catalogStatus === 'failed' && 'Failed to add product to catalog'}
                </div>
              )}

              <div style={{ marginTop: '15px' }}>
                <button
                  onClick={resetForm}
                  style={{
                    backgroundColor: '#28a745',
                    color: 'white',
                    padding: '10px 20px',
                    border: 'none',
                    borderRadius: '4px',
                    cursor: 'pointer',
                    marginRight: '10px'
                  }}
                >
                  Submit Another Product
                </button>
                <button
                  onClick={() => setShowAddForm(false)}
                  style={{
                    backgroundColor: '#6c757d',
                    color: 'white',
                    padding: '10px 20px',
                    border: 'none',
                    borderRadius: '4px',
                    cursor: 'pointer'
                  }}
                >
                  View Catalog
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Products Catalog */}
      <div>
        <h2 style={{ color: '#666', marginBottom: '20px' }}>
          Product Catalog ({products.length})
        </h2>

        {loading && (
          <div style={{
            padding: '40px',
            textAlign: 'center',
>>>>>>> 6193edd (Added)
            fontSize: '16px',
            color: '#007bff'
          }}>
            Loading products...
          </div>
        )}
<<<<<<< HEAD
        
        {error && (
          <div style={{ 
            color: '#dc3545', 
            backgroundColor: '#f8d7da', 
            border: '1px solid #f5c6cb',
            padding: '15px', 
            borderRadius: '4px',
            marginBottom: '20px'
          }}>
            Error: {error}
          </div>
        )}
        
        {!loading && !error && products.length === 0 && (
          <div style={{ 
            padding: '20px', 
            textAlign: 'center', 
            color: '#6c757d',
            fontSize: '16px'
          }}>
            No products found
          </div>
        )}
        
        {!loading && !error && products.length > 0 && (
          <div>
            {products.map(product => (
              <div key={product.id} style={{
                border: '1px solid #dee2e6',
                borderRadius: '4px',
                padding: '15px',
                marginBottom: '10px',
                backgroundColor: '#f8f9fa'
              }}>
                <h3 style={{ margin: '0 0 10px 0', color: '#495057' }}>{product.name}</h3>
                <p style={{ margin: '0', color: '#6c757d' }}>{product.description}</p>
=======

        {!loading && !error && products.length === 0 && (
          <div style={{
            padding: '40px',
            textAlign: 'center',
            color: '#6c757d',
            fontSize: '16px',
            border: '2px dashed #dee2e6',
            borderRadius: '8px'
          }}>
            No products found. Submit a product for AI evaluation to get started!
          </div>
        )}

        {!loading && !error && products.length > 0 && (
          <div style={{ display: 'grid', gap: '15px' }}>
            {products.map(product => (
              <div key={product.id} style={{
                border: '1px solid #dee2e6',
                borderRadius: '8px',
                padding: '20px',
                backgroundColor: '#ffffff',
                boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                  <div style={{ flex: 1 }}>
                    <h3 style={{ margin: '0 0 10px 0', color: '#495057' }}>
                      {product.name}
                    </h3>
                    <p style={{ margin: '0 0 10px 0', color: '#6c757d', lineHeight: '1.4' }}>
                      {product.description}
                    </p>
                    <div style={{ display: 'flex', gap: '20px', fontSize: '14px', color: '#495057' }}>
                      <span><strong>Price:</strong> ${product.price}</span>
                      <span><strong>Vendor:</strong> {product.vendor}</span>
                      {product.ai_evaluation?.score && (
                        <span><strong>AI Score:</strong> {product.ai_evaluation.score}/100</span>
                      )}
                    </div>
                  </div>
                </div>
>>>>>>> 6193edd (Added)
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default App
