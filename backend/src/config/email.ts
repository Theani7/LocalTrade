import sgMail from '@sendgrid/mail';

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const FROM_EMAIL = process.env.SENDGRID_FROM_EMAIL || 'noreply@localtrade.app';

let isConfigured = false;

if (SENDGRID_API_KEY && SENDGRID_API_KEY !== 'SG.your_sendgrid_api_key_here') {
  sgMail.setApiKey(SENDGRID_API_KEY);
  isConfigured = true;
} else {
  console.warn('SendGrid API key missing. Password reset emails will be logged to console.');
}

export interface SendEmailOptions {
  to: string;
  subject: string;
  html: string;
}

export const sendEmail = async ({ to, subject, html }: SendEmailOptions): Promise<void> => {
  if (!isConfigured) {
    const otpMatch = html.match(/\b\d{6}\b/);
    const body = otpMatch
      ? html.replace(otpMatch[0], '******')
      : html;
    console.log('\n════════════════════════════════════════════════════');
    console.log(`📧 Password reset email to: ${to}`);
    console.log(`   Subject: ${subject}`);
    console.log(`   Body:\n${body}`);
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

export { isConfigured };
export default { sendEmail, isConfigured };
