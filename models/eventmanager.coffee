
define "EventManager", ["VoodoocontentModel"], (model) ->
  console.log("defining event manager")
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
        return (uid == Meteor.userId() && fieldNames.length == 1 && (fieldNames[0] == "attending" or fieldNames[0] == "geolocation"))

    )

  if (Meteor.isClient)
    require ["FacebookClient"], (fb) ->

      self.fbLoggedin = (fbapi) ->
        self.fb = fbapi;
        #return #hack to not attend events
        fbapi.api("/me/events", (res) -> _.each(res.data, (e) ->
          Meteor.call("importFacebookEvent",e.id, (err,id) ->
            console.log("inserted event with id:",id);
            if id
              Meteor.users.update(Meteor.userId(), $addToSet: { attending: id})
            #Meteor.call("attendEvent", id, (err, res) -> console.log(err,res));
          )
        ))
        return ## hack to not load friends events
        fbapi.api "/me/friends",
          limit: 3000
        , (res) ->
          numProcessing = 0
          friendprocess = (friendlist) ->
            #console.log("friendlist", friendlist)
            friend = friendlist.shift()
            if (! friend.id?)
              console.log("skipping friend", friend)
              friendprocess(friendlist)
              return
            console.log("getting events for", friend)
            FB.api friend.id + "/events", (e) ->
              #console.log(e)
              events = e.data
              if (events.length <= 0)
                friendprocess(friendlist)
                return
              process = (evts) ->
                numProcessing++
                if (evts.length <= 0)
                  friendprocess(friendlist)
                  return
                #console.log("length before",evts)
                event = evts.shift()
                #console.log("length after",evts)
                if (event?.id?)
                  Meteor.call "importFacebookEvent", event.id, (err,re) ->
                    console.log "imported", err ,re
                    numProcessing--
                    process(evts)
                else
                  console.log("skipping event", event)
                  numProcessing--
                  process(evts)
                if (numProcessing < 20)
                  process(evts)
              process(events)
          # console.log("importing friend events",res.data)
          friendprocess(_.shuffle(res.data))


      self.rsvp = (eventid,confirm) ->
        if (confirm)
          Meteor.users.update(Meteor.userId(), $addToSet: { attending: eventid})
        else
          Meteor.users.update(Meteor.userId(), $pull: { attending: eventid})
        if (self.fb?)
          fbConnection = if confirm then "attending" else "maybe"
          fb.ensureLoggedIn( (res) ->
            self.fb.api(model.getContentById(eventid).sourceId+"/"+fbConnection,"POST", (res) -> console.log(res))
          , "rsvp_event")
      fb.onLoggedIn(self.fbLoggedin)
  return self;