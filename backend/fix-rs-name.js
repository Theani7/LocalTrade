const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '.env');
try {
    let content = fs.readFileSync(envPath, 'utf8');
    // Replace the incorrect replicaSet name with the correct one
    content = content.replace(/replicaSet=atlas-[^&]+/g, 'replicaSet=atlas-e3qonm-shard-0');
    fs.writeFileSync(envPath, content);
    console.log('Successfully updated .env with the correct Replica Set name.');
} catch (err) {
    console.error('Failed to update .env:', err.message);
    process.exit(1);
}
