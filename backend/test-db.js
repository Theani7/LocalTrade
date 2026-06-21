require('dotenv').config();
const mongoose = require('mongoose');

const testConnection = async () => {
  const uri = process.env.MONGODB_URI;
  
  if (!uri) {
    console.error('❌ Error: MONGODB_URI is not defined in .env file.');
    process.exit(1);
  }

  console.log('Attempting to connect to MongoDB...');
  console.log(`URI: ${uri.replace(/:([^:@]+)@/, ':****@')}`); // Hide password for security

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000, // Timeout after 5 seconds
    });
    console.log('✅ Success! Connected to MongoDB.');
    await mongoose.connection.close();
    console.log('Connection closed.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Connection Failed!');
    console.error('Error Name:', error.name);
    console.error('Error Message:', error.message);
    if (error.message.includes('ECONNREFUSED')) {
      console.log('\nPossible causes:');
      console.log('1. Your IP is not whitelisted in MongoDB Atlas.');
      console.log('2. The MongoDB cluster is down or paused.');
      console.log('3. Your local network/DNS is blocking Atlas (SRV records).');
    }
    process.exit(1);
  }
};

testConnection();
