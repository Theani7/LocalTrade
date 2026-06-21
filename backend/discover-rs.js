require('dotenv').config();
const { MongoClient } = require('mongodb');

async function run() {
    let uri = process.env.MONGODB_URI;
    if (!uri) {
        console.error("MONGODB_URI not found");
        return;
    }

    // Remove replicaSet parameter from URI if it exists to allow discovery
    uri = uri.replace(/replicaSet=[^&]+&?/, '');
    
    const client = new MongoClient(uri);
    try {
        console.log("Connecting to discover topology using your credentials...");
        await client.connect();
        const isMaster = await client.db('admin').command({ isMaster: 1 });
        console.log("✅ SUCCESS!");
        console.log("Actual Replica Set Name:", isMaster.setName);
        console.log("\nIf this differs from what's in your .env, that is the problem!");
    } catch (err) {
        console.error("❌ Discovery failed:", err.message);
    } finally {
        await client.close();
    }
}

run();
