const express = require('express');
const { AccessToken } = require('livekit-server-sdk');

const app = express();

const API_KEY = process.env.LIVEKIT_API_KEY || 'devkey';
const API_SECRET = process.env.LIVEKIT_API_SECRET || 'secret';

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  next();
});

app.get('/token', async (req, res) => {
  const room = String(req.query.room || '');
  const identity = String(req.query.identity || '');

  if (!room || !identity) {
    return res.status(400).json({ error: 'room ve identity gerekli' });
  }

  const at = new AccessToken(API_KEY, API_SECRET, {
    identity,
    ttl: '2h',
  });

  at.addGrant({
    roomJoin: true,
    room,
    canPublish: true,
    canSubscribe: true,
  });

  res.json({ token: await at.toJwt() });
});

app.listen(3000, () => console.log('Token sunucusu: http://localhost:3000'));
