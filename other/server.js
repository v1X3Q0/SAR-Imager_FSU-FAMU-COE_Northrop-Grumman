

const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 3003 });

wss.on('connection', function connection(ws) {
  ws.on('message', function incoming(message) {
    console.log('received:' + message);
  });

  ws.send('something');
});
