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
  
  const handleSubmit = async (e) => {
    e.preventDefault()
    try {
      const response = await axios.post(
        'http://localhost:7777/products/evaluate',
        formData
      )
      setEvaluation(response.data.evaluation)
    } catch (error) {
      console.error('Error:', error)
    }
  }
  
  return (
    <div>
      <h1>Vendor Submission Portal</h1>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Vendor Name"
          value={formData.vendorName}
          onChange={(e) => setFormData({...formData, vendorName: e.target.value})}
        />
        <input
          type="text"
          placeholder="Product Name"
          value={formData.productName}
          onChange={(e) => setFormData({...formData, productName: e.target.value})}
        />
        <textarea
          placeholder="Description"
          value={formData.description}
          onChange={(e) => setFormData({...formData, description: e.target.value})}
        />
        <input
          type="number"
          placeholder="Price"
          value={formData.price}
          onChange={(e) => setFormData({...formData, price: e.target.value})}
        />
        <button type="submit">Submit for AI Evaluation</button>
      </form>
      
      {evaluation && (
        <div>
          <h2>AI Evaluation Results</h2>
          <p>Score: {evaluation.score}/100</p>
          <p>Decision: {evaluation.decision}</p>
        </div>
      )}
    </div>
  )
}

export default App
