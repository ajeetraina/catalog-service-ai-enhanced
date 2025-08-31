import { useState, useEffect } from 'react'
import axios from 'axios'

function App() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  
  useEffect(() => {
    fetchProducts()
  }, [])
  
  const fetchProducts = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await axios.get('http://localhost:3000/api/products')
      // Handle both response formats: direct array or nested in products property
      const productsData = response.data.products || response.data
      setProducts(productsData)
      setProducts(response.data.products)
    } catch (error) {
      console.error('Error fetching products:', error)
      setError(`Failed to fetch products: ${error.message}`)
    } finally {
      setLoading(false)
    }
  }
  
  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1 style={{ color: '#333', marginBottom: '20px' }}>AI-Enhanced Catalog Service</h1>
      <div>
        <h2 style={{ color: '#666', marginBottom: '15px' }}>Products</h2>
        
        {loading && (
          <div style={{ 
            padding: '20px', 
            textAlign: 'center', 
            fontSize: '16px',
            color: '#007bff'
          }}>
            Loading products...
          </div>
        )}
        
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
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default App
