const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
try {
    let content = fs.readFileSync(envPath, 'utf8');
    content = content.replace(/^MONGODB_URI=.*/m, 'MONGODB_URI=mongodb://127.0.0.1:27017/sajhabazar');
    fs.writeFileSync(envPath, content);
    console.log('Successfully updated .env to use local MongoDB URI.');
} catch (err) {
    console.error('Failed to update .env:', err.message);
    process.exit(1);
}
