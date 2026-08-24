const AfricasTalking = require('africastalking')({
  apiKey: process.env.AT_API_KEY,
  username: process.env.AT_USERNAME,
});

const sms = AfricasTalking.SMS;

// Sends an SMS to a single phone number.
// Uganda numbers should be in international format, e.g. +2567XXXXXXXX.
async function sendSms(to, message) {
  try {
    const result = await sms.send({
      to: [to],
      message,
      from: process.env.AT_SENDER_ID || undefined,
    });
    console.log('SMS sent:', JSON.stringify(result));
    return { success: true, result };
  } catch (err) {
    console.error('Failed to send SMS:', err.message);
    return { success: false, error: err.message };
  }
}

module.exports = { sendSms };