const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoUri = 'mongodb+srv://James:!James123@fitscaledb.ts50o.mongodb.net/fitscale?retryWrites=true&w=majority&appName=fitscaleDB';
    await mongoose.connect(mongoUri, {
     
    });
    console.log('MongoDB connected');
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

module.exports = connectDB;
