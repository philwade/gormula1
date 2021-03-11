import './styles.scss'
import { Elm } from './src/Main.elm'

var app = Elm.Main.init({
  node: document.querySelector('main'),
  flags: 1
});

app.ports.requestTrackLength.subscribe(function(id) {
  let track = document.getElementById(id);

  if(track !== null && track.getTotalLength) {
    app.ports.gotTrackLength.send(track.getTotalLength());
  }
});

app.ports.getPointAtTrackDistance.subscribe(function({ id, position }) {
  let track = document.getElementById(id);

  if(track !== null && track.getPointAtLength) {
    app.ports.gotPointAtTrackDistance.send(track.getPointAtLength(position));
  }
});

