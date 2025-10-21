// server.js
const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
app.use(express.json());

const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/testdb';
const port = process.env.PORT || 3000;
let dbClient;
let collection;

async function connectDB() {
  dbClient = new MongoClient(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });
  await dbClient.connect();
  const db = dbClient.db('testdb');
  collection = db.collection('items');
  console.log('Connected to MongoDB');
}

app.get('/', (req, res) => {
  res.send({ message: 'Node.js + MongoDB app running' });
});

app.get('/items', async (req, res) => {
  const items = await collection.find({}).toArray();
  res.send(items);
});

app.post('/items', async (req, res) => {
  const item = req.body;
  const result = await collection.insertOne(item);
  res.send({ insertedId: result.insertedId });
});

process.on('SIGINT', async () => {
  if (dbClient) await dbClient.close();
  process.exit();
});

connectDB()
  .then(() => {
    app.listen(port, () => console.log(`Server listening on ${port}`));
  })
  .catch(err => {
    console.error('Failed to connect to MongoDB:', err);
    process.exit(1);
  });

