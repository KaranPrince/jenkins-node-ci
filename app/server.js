const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// serve static files from ./app
app.use(express.static(path.join(__dirname, 'app')));

// default route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'app', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 server running on ${PORT}`);
});
