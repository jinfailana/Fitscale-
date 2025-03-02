const express = require('express');
const User = require('../models/User');

const router = express.Router();

router.post('/', async (req, res) => {
  const { username, email } = req.body;
  const user = new User({ username, email, createdAt: new Date() });
  try {
    await user.save();
    res.status(201).send(user);
  } catch (err) {
    res.status(400).send(err);
  }
});

router.put('/:email', async (req, res) => {
  const { email } = req.params;
  const { username, updatedEmail } = req.body;
  try {
    const user = await User.findOneAndUpdate(
      { email },
      { username, email: updatedEmail, updatedAt: new Date() },
      { new: true }
    );
    res.send(user);
  } catch (err) {
    res.status(400).send(err);
  }
});

module.exports = router;
