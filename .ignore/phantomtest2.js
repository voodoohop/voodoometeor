var url = "http://voodoometeor-11724.onmodulus.net/contentDetail/popload-gig-28-com-omar-souleyman";
var page = require('webpage').create();
page.open(url);
setInterval(function() {
  var ready = page.evaluate(function () {
    if (typeof Meteor !== 'undefined'  && typeof(Meteor.status) !== 'undefined' && Meteor.status().connected) {
      Deps.flush();
      return DDP._allSubscriptionsReady();
    }
    return false;
  });
  if (ready) {
    var response = page.evaluate(function() {
      return Spiderable;    });
    if(response.httpStatusCode != 200  || Object.keys(response.httpHeaders).length > 0) {
      console.log('<!-- HTTP-RESPONSE:' + response.httpStatusCode + ' '              + JSON.stringify(response.httpHeaders) + ' -->');    }
    var out = page.content;
    out = out.replace(/<script[^>]+>(.|\n|\r)*?<\/script\s*>/ig, '');
    out = out.replace('<meta name="fragment" content="!">', '');
    console.log(out);
    phantom.exit();  }},
  100);
