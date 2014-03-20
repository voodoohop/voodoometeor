var url = 'http://voodoohop.meteor.com';
var page = require('webpage').create();
page.open(url);
console.log('postopen');
setInterval(function() {
  var ready = page.evaluate(function () {
    if (typeof Meteor !== 'undefined' && typeof(Meteor.status) !== 'undefined')
      return 1;
    if (typeof Meteor !== 'undefined' && typeof(Meteor.status)
      !== 'undefined' && Meteor.status().connected) {
      Deps.flush();
      return DDP._allSubscriptionsReady();
    }
    return false;
  });
  console.log(ready);
  if (ready) {
    var out = page.content;
    out = out.replace(/<script[^>]+>(.|\n|\r)*?<\/script\s*>/ig, '');
    out = out.replace('<meta name="fragment" content="!">', '');
    console.log(out);
    phantom.exit();
  }
}, 100);