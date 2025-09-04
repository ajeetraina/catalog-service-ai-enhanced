import React from 'react';
import ProductForm from './components/ProductForm';

function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4">
          <h1 className="text-3xl font-bold text-gray-900">
            🤖 AI-Enhanced Catalog Service
          </h1>
          <p className="text-gray-600 mt-2">Powered by cagent Multi-Agent Runtime</p>
        </div>
      </header>
      
      <main className="max-w-7xl mx-auto py-6 px-4">
        <ProductForm />
      </main>
    </div>
  );
}

export default App;
