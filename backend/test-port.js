const net = require('net');

const hosts = [
  'ac-jukewya-shard-00-00.xdzvcez.mongodb.net',
  'ac-jukewya-shard-00-01.xdzvcez.mongodb.net',
  'ac-jukewya-shard-00-02.xdzvcez.mongodb.net'
];

hosts.forEach(host => {
  const client = new net.Socket();
  client.setTimeout(5000);
  
  console.log(`Testing connection to ${host}:27017...`);
  
  client.connect(27017, host, () => {
    console.log(`✅ Connected to ${host}:27017`);
    client.destroy();
  });

  client.on('error', (err) => {
    console.error(`❌ Failed to connect to ${host}:27017 - ${err.message}`);
    client.destroy();
  });

  client.on('timeout', () => {
    console.error(`❌ Timeout connecting to ${host}:27017`);
    client.destroy();
  });
});
