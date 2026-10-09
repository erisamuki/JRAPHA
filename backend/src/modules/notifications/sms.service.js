
/**
 * JRapha SMS Service
 * SMS is disabled until provider credentials are configured.
 */

async function sendSms(to, message) {
  console.warn(
    'SMS skipped: SMS provider is not configured.'
  );

  return {
    success: false,
    disabled: true,
    message: 'SMS service is disabled.'
  };
}

module.exports = {
  sendSms
};