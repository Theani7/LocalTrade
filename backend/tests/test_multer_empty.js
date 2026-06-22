const request = require('supertest');
const express = require('express');
const multer = require('multer');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.patch('/profile', upload.single('profileImage'), (req, res) => {
  res.json({ body: req.body });
});

request(app)
  .patch('/profile')
  .field('address', '{"city": "Kathmandu"}')
  .end((err, res) => {
    console.log(res.body);
  });
