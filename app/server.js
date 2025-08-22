const express = require('express');
const app = express();

app.get('/', (_req, res) => res.status(200).send('OK'));

// Export the app for supertest
module.exports = app;

// Start server only when not under tests
if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`Server listening on ${port}`));
}
