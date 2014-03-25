var url = "http://localhost:3000/content/events/0";
var page = require('webpage').create();
var system = require('system');

page.onConsoleMessage = function(msg) {
  system.stderr.writeLine('console: ' + msg);
};

page.open(url, function(status) {
  console.log("status",status);
  console.log('evaluating page',page);

  setInterval(function() {
  var ready = page.evaluate(function () {
    console.log("page evaluating");
    var res = false;
    if (typeof Meteor !== 'undefined'  && typeof(Meteor.status) !== 'undefined' && Meteor.status().connected) {
      Deps.flush();
      res = DDP._allSubscriptionsReady();
      console.log(_.map(Meteor.connection._subscriptions,function(s) {return "name:"+ s.name+" ready:"+s.ready}));
    }
    console.log("subs ready:", res);
    return res;
  });
 /* if (ready) {
    var response = page.evaluate(function() {
      return Spiderable;    });
    if(response.httpStatusCode != 200  || Object.keys(response.httpHeaders).length > 0) {
      console.log('<!-- HTTP-RESPONSE:' + response.httpStatusCode + ' '              + JSON.stringify(response.httpHeaders) + ' -->');    }
    var out = page.content;
    out = out.replace(/<script[^>]+>(.|\n|\r)*?<\/script\s*>/ig, '');
    out = out.replace('<meta name="fragment" content="!">', '');
    console.log(out);
    phantom.exit();  }
    */
},  1000)});

