define "EventManager",["VoodoocontentModel"], (model) ->


  self = {}

  if Meteor.isServer

    Accounts.onCreateUser( (options, user) ->
      user.attending = [];
      return user;
    )

    #Meteor.users.update({}, {$set: {attending: []}})

    #console.log("users",Meteor.users.find({}).fetch())

    Meteor.methods
      attendEvent: (eventid) ->
        this.unblock();
        console.log(""+this.userId+" attending" +eventid)
        Meteor.users.update(this.userId, $addToSet: { attending: eventid})

    Meteor.users.allow(
      update: (uid, doc, fieldNames, modifier) ->
        return (uid == Meteor.userId() && fieldNames.length == 1 && fieldNames[0] == "attending")

    )

  if (Meteor.isClient)
    self.fbLoggedin = (fbapi) ->
      self.fb = fbapi;
      #return #hack to not attend events
      fbapi.api("/me/events/attending", (res) -> _.each(res.data, (e) ->
        Meteor.call("importFacebookEvent",e.id, (err,id) ->
          console.log("inserted event with id:",id);
          if id
            Meteor.users.update(Meteor.userId(), $addToSet: { attending: id})
          #Meteor.call("attendEvent", id, (err, res) -> console.log(err,res));
        )
      ))
    self.rsvp = (eventid,confirm) ->
      if (confirm)
        Meteor.users.update(Meteor.userId(), $addToSet: { attending: eventid})
      else
        Meteor.users.update(Meteor.userId(), $pull: { attending: eventid})
      if (self.fb?)
        fbConnection = if confirm then "attending" else "maybe"
        doRsvp = -> self.fb.api(model.getContentById(eventid).sourceId+"/"+fbConnection,"POST", (res) -> console.log(res))
        if (Meteor.user().services.facebook.permissions.rsvp_event)
          doRsvp()
        else
          FB.login( ->
            doRsvp()
          , {scope:"rsvp_event"});
  return self;