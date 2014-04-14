

var wormapp, worminterval, wormcount;

function wormApp2() {
  wormcount++;
  if (wormcount % 2 == 0){
    wormapp.mouse.y -= 40
  } else {
    wormapp.mouse.y += 40;
  }

  if (wormcount > 30) {
    window.clearInterval( worminterval );
  }
}



Template.wormcanvas.rendered = function() {
  return
  if (!wormapp) {
    console.log("worminit");
    wormapp = new DrawWorm('wormcanvas');
  }
  wormapp.initialize();
  wormcount = 0;
  worminterval = setInterval( wormApp2, 100 );
};