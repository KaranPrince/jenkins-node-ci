// app/server.js
// Reuse the exported Express app from app.js and start the server when run directly.

const app = require('./app'); // <- app/app.js exports the Express app

// Start server only when not under tests
if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`Server listening on ${port}`));
}

module.exports = app;
