const express = require('express');
const request = require('supertest');
const upload = require('../src/middleware/uploadMiddleware');

const app = express();

app.patch('/api', upload.single('profileImage'), (req, res) => {
  res.json({ body: req.body, file: req.file });
});

request(app)
  .patch('/api')
  .field('address', '{"city": "Kathmandu"}')
  .end((err, res) => {
    console.log(res.body);
  });
