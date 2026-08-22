const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true', // true for port 465, false for 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

// Sends a heads-up email to all currently approved admins when a new
// user registers and needs approval. This is informational only —
// the admin still logs into the JRapha dashboard to approve/reject.
async function notifyAdminsOfNewRegistration(pendingUser, db) {
  try {
    const adminsResult = await db.query(
      `SELECT email FROM users WHERE role = 'admin' AND status = 'approved'`
    );

    if (adminsResult.rows.length === 0) {
      console.warn('No approved admins found to notify of new registration');
      return;
    }

    const adminEmails = adminsResult.rows.map((row) => row.email);

    await transporter.sendMail({
      from: `"JRapha System" <${process.env.SMTP_USER}>`,
      to: adminEmails.join(','),
      subject: 'JRapha: New account pending approval',
      text: `A new user has registered and is awaiting approval.\n\n` +
        `Name: ${pendingUser.full_name}\n` +
        `Email: ${pendingUser.email}\n` +
        `Role requested: ${pendingUser.role}\n\n` +
        `Log into the JRapha admin dashboard to review and approve or reject this request.`,
      html: `<p>A new user has registered and is awaiting approval.</p>
             <ul>
               <li><strong>Name:</strong> ${pendingUser.full_name}</li>
               <li><strong>Email:</strong> ${pendingUser.email}</li>
               <li><strong>Role requested:</strong> ${pendingUser.role}</li>
             </ul>
             <p>Log into the JRapha admin dashboard to review and approve or reject this request.</p>`,
    });

    console.log(`Admin notification email sent for new user: ${pendingUser.email}`);
  } catch (err) {
    // Never let an email failure block registration itself
    console.error('Failed to send admin notification email:', err.message);
  }
}

module.exports = { notifyAdminsOfNewRegistration };