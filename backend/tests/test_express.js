const express = require('express');
const request = require('supertest');
const multer = require('multer');

const sanitizeObject = (obj) => {
  if (obj && typeof obj === 'object') {
    for (const key in obj) {
      if (key.startsWith('$')) {
        delete obj[key];
      } else {
        sanitizeObject(obj[key]);
      }
    }
  }
};

const customMongoSanitize = (req, res, next) => {
  if (req.body) sanitizeObject(req.body);
  if (req.query) sanitizeObject(req.query);
  if (req.params) sanitizeObject(req.params);
  next();
};

const app = express();
app.use(customMongoSanitize);

const upload = multer();

app.patch('/api', upload.none(), (req, res) => {
  res.json({ body: req.body });
});

request(app)
  .patch('/api')
  .field('address', '{"city": "Kathmandu"}')
  .end((err, res) => {
    console.log(res.body);
  });
