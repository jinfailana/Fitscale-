const express = require('express');
const router = express.Router();
const { createUser, getUserById } = require('../controller/userController');

// Route to create a new user
router.post('/', createUser);

// Route to get a user by ID
router.get('/:id', getUserById);

module.exports = router;
