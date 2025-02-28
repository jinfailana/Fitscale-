const mongoose = require('mongoose');

// Main user schema
const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true },
    password: { type: String, required: true },

    // Other user details (optional for later)
    fullName: { type: String, trim: true },
    birthdate: { type: Date },
    gender: { type: String, enum: ['Male', 'Female'] },
    height: { type: Number },
    weight: { type: Number },
    activityLevel: {
      type: String,
      enum: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extra Active'],
    },
    gymEquipmentPreference: { type: String, enum: ['Body Weight', 'With Equipment'] },
    fitnessGoal: { type: String, enum: ['Lose Weight', 'Build Muscle', 'Stay Fit'] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
