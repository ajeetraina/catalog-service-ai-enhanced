import React, { useState } from 'react';
import axios from 'axios';

const ProductForm = () => {
  const [formData, setFormData] = useState({
    vendorName: '',
    productName: '',
    description: '',
    price: '',
    category: ''
  });
  
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await axios.post(
        `${import.meta.env.VITE_API_URL}/api/products/evaluate`,
        formData
      );
      setResult(response.data);
    } catch (error) {
      setResult({
        success: false,
        error: error.response?.data?.message || error.message
      });
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold mb-6">Submit Product for AI Evaluation</h2>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Vendor Name
              </label>
              <input
                type="text"
                name="vendorName"
                value={formData.vendorName}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="e.g., NVIDIA"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Product Name
              </label>
              <input
                type="text"
                name="productName"
                value={formData.productName}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="e.g., Jetson Nano Developer Kit"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Price ($)
              </label>
              <input
                type="number"
                name="price"
                value={formData.price}
                onChange={handleInputChange}
                required
                step="0.01"
                min="0"
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                placeholder="199.99"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Category
              </label>
              <select
                name="category"
                value={formData.category}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select a category</option>
                <option value="Electronics">Electronics</option>
                <option value="Software">Software</option>
                <option value="Hardware">Hardware</option>
                <option value="Tools">Tools</option>
                <option value="Books">Books</option>
              </select>
            </div>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Product Description
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              required
              rows="4"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="Describe the product features, specifications, and benefits..."
            />
          </div>
          
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white py-3 px-6 rounded-md hover:bg-blue-700 disabled:bg-blue-400 transition-colors"
          >
            {loading ? '🤖 AI Agents Evaluating...' : '🚀 Submit for Evaluation'}
          </button>
        </form>
        
        {result && (
          <div className="mt-8 p-6 bg-gray-50 rounded-lg">
            <h3 className="text-xl font-bold mb-4">Evaluation Result</h3>
            {result.success ? (
              <div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                  <div className="text-center">
                    <div className={`text-3xl font-bold ${
                      result.data.score >= 70 ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {result.data.score}/100
                    </div>
                    <div className="text-sm text-gray-600">AI Score</div>
                  </div>
                  <div className="text-center">
                    <div className={`text-xl font-bold ${
                      result.data.decision === 'APPROVED' ? 'text-green-600' : 
                      result.data.decision === 'REJECTED' ? 'text-red-600' : 'text-yellow-600'
                    }`}>
                      {result.data.decision}
                    </div>
                    <div className="text-sm text-gray-600">Decision</div>
                  </div>
                  <div className="text-center">
                    <div className="text-xl font-bold text-blue-600">
                      {result.data.processing_time_ms}ms
                    </div>
                    <div className="text-sm text-gray-600">Processing Time</div>
                  </div>
                </div>
                
                <div className="bg-white p-4 rounded-lg">
                  <h4 className="font-semibold mb-2">AI Reasoning:</h4>
                  <p className="text-gray-700">{result.data.reasoning}</p>
                </div>
                
                {result.data.insights && (
                  <div className="mt-4 bg-white p-4 rounded-lg">
                    <h4 className="font-semibold mb-2">AI Insights:</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {result.data.insights.strengths?.length > 0 && (
                        <div>
                          <h5 className="font-medium text-green-600 mb-1">Strengths:</h5>
                          <ul className="text-sm text-gray-700 list-disc list-inside">
                            {result.data.insights.strengths.map((strength, idx) => (
                              <li key={idx}>{strength}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                      {result.data.insights.concerns?.length > 0 && (
                        <div>
                          <h5 className="font-medium text-red-600 mb-1">Concerns:</h5>
                          <ul className="text-sm text-gray-700 list-disc list-inside">
                            {result.data.insights.concerns.map((concern, idx) => (
                              <li key={idx}>{concern}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-red-600">
                <strong>Error:</strong> {result.error || result.message}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductForm;
