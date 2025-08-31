// Add before line 84 in app.js
app.get('/api/products', (req, res) => {
  res.json({
    products: [
      { id: 1, name: "Smart Watch", description: "AI-powered", price: 299, ai_score: 85 },
      { id: 2, name: "Earbuds Pro", description: "Noise cancelling", price: 199, ai_score: 90 }
    ]
  });
});
