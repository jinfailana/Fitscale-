const mongoose = require('mongoose');

// Define a sub-schema for workout level
const workoutLevelSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  }
});

// Main user schema
const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    trim: true,
  },
  birthdate: {
    type: Date,
    required: true,
  },
  gender: {
    type: String,
    enum: ['Male', 'Female'],
    required: true,
  },
  height: {
    type: Number,
    required: true,
  },
  weight: {
    type: Number,
    required: true,
  },
  activityLevel: {
    type: String,
    enum: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'],
    required: true,
  },
  gymEquipmentPreference: {
    type: String,
    enum: ['Body Weight', 'With Equipment'],
    required: true,
  },
  fitnessGoal: {
    type: String,
    enum: ['Lose Weight', 'Build Muscle', 'Stay Fit'],
    required: true,
  },
  workoutLevel: {
    type: workoutLevelSchema,
    required: true,
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
