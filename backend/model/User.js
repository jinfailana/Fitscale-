const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Main user schema
const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true },
    password: { type: String, required: true },
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

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) {
    next(err);
  }
});

module.exports = mongoose.model('User', userSchema);
