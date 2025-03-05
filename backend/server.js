const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');
const userRoutes = require('./routes/userRoutes');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');

// Load environment variables from .env file
dotenv.config();
// Ensure your .env file contains the correct API keys
// Example: BREVO_API_KEY=your-new-api-key

// Connect to MongoDB Atlas
connectDB();

const app = express();
const port = process.env.PORT || 3000;

// Middleware for JSON parsing and enabling CORS
app.use(express.json());
app.use(cors());
app.use(bodyParser.json());


// Define routes
app.use('/api/users', userRoutes);

// Default route for testing server connection
app.get('/', (req, res) => {
  res.send('API is running...');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));

