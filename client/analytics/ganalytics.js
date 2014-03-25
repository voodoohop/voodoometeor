Meteor.startup(function () {
  Template.mainlayout.rendered = _.once(function(){
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

    ga('create', 'UA-49330747-1', 'voodoohop.com');


    console.log("inited google analytics", ga);
    Meteor.setTimeout(function() {
    var eventHook = function(template, action, label) {
      var events = {};
      events[action+" "+label] = function(e,tmpl) {
        if (action.toLowerCase().substr(0,8) == "keypress") return;	//Lets ignore these they could be dangerous
        ga("send","event",template, action, label, {formdata: $(tmpl.findAll('input[type=text],input[type=number],input[type=email],input[type=check],input[type=search],textarea,select')).serializeArray()});
        console.log("ga","send","event",template, action, label, {formdata: $(tmpl.findAll('input[type=text],input[type=number],input[type=email],input[type=check],input[type=search],textarea,select')).serializeArray()});
        //Meteor.call("_Tevent", {type:'event', template: template, selector: selector, formdata: $(tmpl.findAll('input[type=text],input[type=number],input[type=email],input[type=check],input[type=search],textarea,select')).serializeArray(), connection: Meteor.connection._lastSessionId});
      };
      if(typeof Template[template].events == "function") Template[template].events(events);
      else console.log('WARNING', 'Depreciated style Meteor events are not supported such as the ones on ' + template);
    }

    for(var key in Template) {
      var tmpl = Template[key], events = tmpl._events;
      //console.log("analytics events hooks:",events);
      if(!events) continue;
      for(var i in events) {
        //var eventKey = ""+events[i].events+" "+events[i].selector;
        console.log("analytics adding event hook", key, ""+events[i].events+" "+events[i].selector)

        eventHook(key, events[i].events, events[i].selector);
      }
    } }
    ,500);

    //Page Changes
     if(typeof(Router) != "undefined")
      Router.onAfterAction( function() {
        ga('send','pageview', this.path);// {type: 'page', title: document.title, path: this.path, params: this.params,  connection: Meteor.connection._lastSessionId});
        console.log("ga",'send','pageview', this.path);
      });


    var winstate = false;
    window.addEventListener("focus", function(event) {
      if(winstate) return;
      winstate = true;
      //Meteor.call("_Tevent", {type:'event', template: "", selector: "Window activated", connection: Meteor.connection._lastSessionId});
    }, false);

    window.addEventListener("blur", function(event) {
      winstate=false;
      //Meteor.call("_Tevent", {type:'event', template: "", selector: "Window in background", connection: Meteor.connection._lastSessionId});
    }, false);

    window.addEventListener("error", function(event) {
      var stack = event && event.error && event.error.stack && event.error.stack.toString();
      //if(stack && event.lineno)
        //Meteor.call("_Tevent", {type:'event', template:"", error: { stack: stack, line: event.lineno, filename: event.filename }, selector: "Javascript Error", connection: Meteor.connection._lastSessionId});

    });

  });
});