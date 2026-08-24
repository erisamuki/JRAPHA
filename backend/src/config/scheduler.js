const cron = require('node-cron');
const { sendUpcomingAppointmentReminders } = require('../modules/notifications/reminder.job');

// Runs every hour, on the hour. Sends reminders for appointments happening
// in the next 24 hours that haven't already been reminded.
function startReminderScheduler() {
  cron.schedule('0 * * * *', async () => {
    console.log('Running appointment reminder job...');
    await sendUpcomingAppointmentReminders(24);
  });
  console.log('Appointment reminder scheduler started (runs hourly).');
}

module.exports = { startReminderScheduler };