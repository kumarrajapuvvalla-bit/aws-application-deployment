/**
 * Simple Node.js web application.
 *
 * This Express application exposes two endpoints:
 *   GET /         – returns a welcome message
 *   GET /health   – returns 200 OK for health checks
 */
const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Welcome to the AWS Application Deployment demo!');
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
