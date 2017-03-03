const WebSocket = require('ws');
const gdax = require('gdax');
const moment = require('moment');

const ws = new WebSocket('http://10.137.164.211:3333', {perMessageDeflate: false});
ws.on('open', () => console.log('socket open'));
const pub = new gdax.PublicClient();
const sTime = '2016-02-08 09:00:26';
const eTime = '2016-02-08 09:30:26';
setInterval(() => {
  pub.getProductHistoricRates({ start: sTime,  end: eTime, granularity: 1000 }, (err, res, data) => {
    console.log(data);
    if (data == "message: rate limit exceeded"){
      ws.terminate();
    }
    ws.send(JSON.stringify(data));
  })
}, 500);
