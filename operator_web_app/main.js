const BOSH_SERVICE = 'ws://10.200.0.138:5280/ws';
const nick = 'operator';
let connection = null;

const logContainer = document.querySelector('#log');
function log(msg)
{
  const textDiv = document.createElement('div');
  textDiv.appendChild(document.createTextNode(msg));
  logContainer.appendChild(textDiv);
}

function onConnect(status)
{
  if (status == Strophe.Status.CONNECTING) {
    log('Strophe is connecting.');
  } else if (status == Strophe.Status.CONNFAIL) {
    log('Strophe failed to connect.');
    document.querySelector('#connect').value = 'connect';
  } else if (status == Strophe.Status.DISCONNECTING) {
    log('Strophe is disconnecting.');
  } else if (status == Strophe.Status.DISCONNECTED) {
    log('Strophe is disconnected.');
    document.querySelector('#connect').value = 'connect';
  } else if (status == Strophe.Status.CONNECTED) {
    log('Strophe is connected.');
    log('ECHOBOT: Send a message to ' + connection.jid + ' to talk to me.');

    window.c = connection;
    // connection.addHandler(onMessage, null, 'message', null, null,  null);
    connection.addHandler((stanza) => {
      console.log('MUX', stanza);
      const from = stanza.getAttribute('from');
      if (from && stanza.nodeName === 'message') {
        const roomName = from.split("/")[0];
        connection.muc.join(roomName, nick, onMessage(roomName));
      }
      return true;
    }, null, null, null, null,  null);
    connection.send($pres().tree());
  }
}

const onMessage = (roomName) => (msg) => {
  console.log('onMessage', msg);
  var to = msg.getAttribute('to');
  var from = msg.getAttribute('from');
  const fromNick = from.split('/')[1];
  var type = msg.getAttribute('type');
  var elems = msg.getElementsByTagName('body');

  if (['chat', 'groupchat'].indexOf(type) > -1 && elems.length > 0 && fromNick !== nick) {
    var body = elems[0];

    log('ECHOBOT: I got a message from ' + from + ': ' +
      Strophe.getText(body));

    connection.muc.groupchat(roomName, Strophe.getText(body));

    log('ECHOBOT: I sent ' + from + ': ' + Strophe.getText(body));
  }

  // we must return true to keep the handler alive.
  // returning false would remove it after it finishes.
  return true;
}

connection = new Strophe.Connection(BOSH_SERVICE);

// Uncomment the following lines to spy on the wire traffic.
//connection.rawInput = function (data) { log('RECV: ' + data); };
//connection.rawOutput = function (data) { log('SEND: ' + data); };

// Uncomment the following line to see all the debug output.
//Strophe.log = function (level, msg) { log('LOG: ' + msg); };


const connectButton = document.querySelector('#connect');
const jid = document.querySelector('#jid');
const pass = document.querySelector('#pass');
connectButton.addEventListener('click', () => {
  if (connectButton.value == 'connect') {
    connectButton.value = 'disconnect';

    connection.connect(jid.value, pass.value, onConnect);
  } else {
    connectButton.value = 'connect';
    connection.disconnect();
  }
});
