const BOSH_SERVICE = 'ws://10.200.0.138:5280/ws';
const API_URL = 'http://10.200.0.154:4567'
const nick = 'operator';
const password = 'super_secret_operator_pass';
let connection = null;

const requestContainer = document.querySelector('#requests');
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
    log('Logging in');
  } else if (status == Strophe.Status.CONNFAIL) {
    log('Failed to log in');
    document.querySelector('#connect').value = 'connect';
  } else if (status == Strophe.Status.DISCONNECTING) {
    log('Logging out');
  } else if (status == Strophe.Status.DISCONNECTED) {
    log('Logged out');
    document.querySelector('#connect').value = 'connect';
  } else if (status == Strophe.Status.CONNECTED) {
    log('Log in successful. Waiting for engagements');

    connection.addHandler((stanza) => {
      const from = stanza.getAttribute('from');
      if (from && stanza.nodeName === 'message') {
        const roomName = from.split('/')[0];
        const visitorName = from.split('-')[0];
        startEngagement(roomName, visitorName);
      }
      return true;
    }, null, null, null, null,  null);
    connection.send($pres().tree());
  }
}

function startEngagement(roomName, visitorName) {
  let headers = new Headers();
  headers.append('Authorization', 'Basic ' + btoa(visitorName + ":" + password));
  fetch(`${API_URL}/cat_pics`, {headers}).then((response) => {
    return response.json();
  }).then((catPicQueries) => {
    catPicQueries.forEach((query) => {
      const row = document.createElement('div');
      row.appendChild(document.createTextNode(JSON.stringify(query)));
      requestContainer.appendChild(row);
    });
  });
  connection.muc.join(roomName, nick, onMessage(roomName));
}

const onMessage = (roomName) => (msg) => {
  var to = msg.getAttribute('to');
  var from = msg.getAttribute('from');
  const fromNick = from.split('/')[1];
  var type = msg.getAttribute('type');
  var elems = msg.getElementsByTagName('body');

  if (['chat', 'groupchat'].indexOf(type) > -1 && elems.length > 0 && fromNick !== nick) {
    var body = elems[0];

    log(`${fromNick}: ${Strophe.getText(body)}`)

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
