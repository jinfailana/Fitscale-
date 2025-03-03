const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();
sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendVerificationCode = functions.https.onCall(async (data, context) => {
  const { email, code } = data;

  const msg = {
    to: email,
    from: "your-verified-sender@yourdomain.com", // Replace with your SendGrid verified sender
    subject: "Verify your email for Fitscale",
    text: `Your verification code is: ${code}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #DF4D0F;">Fitscale Email Verification</h2>
        <p>Your verification code is:</p>
        <h1 style="color: #DF4D0F; font-size: 32px; letter-spacing: 5px;">${code}</h1>
        <p>This code will expire in 10 minutes.</p>
      </div>
    `,
  };

  try {
    await sgMail.send(msg);
    return { success: true };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send verification email"
    );
  }
});
