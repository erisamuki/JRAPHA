const db = require('../../config/db');
const { sendSms } = require('./sms.service');

// Finds appointments scheduled within the given lookahead window that
// haven't been sent a reminder yet, sends an SMS to each patient, and
// marks reminder_sent = true. Designed to be run periodically (e.g. hourly).
//
// hoursAhead: how far in advance to remind (e.g. 24 for a day-before reminder)
async function sendUpcomingAppointmentReminders(hoursAhead = 24) {
  try {
    const result = await db.query(
      `SELECT a.id, a.scheduled_at, p.full_name, p.phone
       FROM appointments a
       JOIN patients p ON p.id = a.patient_id
       WHERE a.status = 'scheduled'
         AND a.reminder_sent = false
         AND a.scheduled_at BETWEEN now() AND (now() + ($1 || ' hours')::interval)
         AND p.phone IS NOT NULL`,
      [hoursAhead]
    );

    const appointments = result.rows;
    if (appointments.length === 0) {
      console.log('No appointment reminders due right now.');
      return { sent: 0 };
    }

    let sentCount = 0;

    for (const appt of appointments) {
      const time = new Date(appt.scheduled_at).toLocaleString('en-UG', {
        dateStyle: 'medium',
        timeStyle: 'short',
      });
      const message = `Hi ${appt.full_name}, this is a reminder of your appointment at JRapha on ${time}. Please arrive on time. Thank you.`;

      const smsResult = await sendSms(appt.phone, message);

      await db.query(
        `INSERT INTO notifications (patient_id, type, channel, message, status, sent_at)
         SELECT patient_id, 'appointment_reminder', 'sms', $1, $2, $3
         FROM appointments WHERE id = $4`,
        [message, smsResult.success ? 'sent' : 'failed', smsResult.success ? new Date() : null, appt.id]
      );

      if (smsResult.success) {
        await db.query(`UPDATE appointments SET reminder_sent = true WHERE id = $1`, [appt.id]);
        sentCount += 1;
      }
    }

    console.log(`Sent ${sentCount}/${appointments.length} appointment reminders.`);
    return { sent: sentCount, total: appointments.length };
  } catch (err) {
    console.error('sendUpcomingAppointmentReminders error:', err);
    return { sent: 0, error: err.message };
  }
}

module.exports = { sendUpcomingAppointmentReminders };