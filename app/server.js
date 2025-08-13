const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 80;

// Serve static HTML
app.use(express.static(path.join(__dirname, 'app')));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'app', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`🚀 Node.js server running on port ${PORT}`);
});
