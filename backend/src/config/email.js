const sgMail = require('@sendgrid/mail');

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const FROM_EMAIL = process.env.SENDGRID_FROM_EMAIL || 'noreply@localtrade.app';

let isConfigured = false;

if (SENDGRID_API_KEY && SENDGRID_API_KEY !== 'SG.your_sendgrid_api_key_here') {
  sgMail.setApiKey(SENDGRID_API_KEY);
  isConfigured = true;
} else {
  console.warn('SendGrid API key missing. Password reset emails will be logged to console.');
}

const sendEmail = async ({ to, subject, html }) => {
  if (!isConfigured) {
    console.log('\n════════════════════════════════════════════════════');
    console.log(`📧 Password reset email to: ${to}`);
    console.log(`   Subject: ${subject}`);
    console.log(`   Body:\n${html}`);
    console.log('════════════════════════════════════════════════════\n');
    return;
  }

  await sgMail.send({
    to,
    from: FROM_EMAIL,
    subject,
    html,
  });
};

module.exports = { sendEmail, isConfigured };
