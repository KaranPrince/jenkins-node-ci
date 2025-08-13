const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 80;

// Serve static HTML
app.use(express.static(path.join(__dirname, 'app')));

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
