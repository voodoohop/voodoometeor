
define "EventManager", ["VoodoocontentModel","FacebookApiHelpers"], (model, fbHelpers) ->
  console.log("defining event manager")
  self = {}

  if Meteor.isServer
    Accounts.onCreateUser( (options, user) ->
      user.attending = [];
      user.eventTickets = [];
      return user;
    )

    Meteor.methods
      updateTicketName: (eventid, ticketindex, name) ->
        mongoop = {}
        mongoop["eventTickets.#{eventid}.#{ ticketindex }.nameOnList"] = name
        mongoop["eventTickets.#{eventid}.#{ ticketindex }.changedName"] = true
        console.log("updated ticket name", this.userId, {$set: mongoop})
        Meteor.users.update(this.userId, {$set: mongoop})
      attendEvent: (eventid) ->
        this.unblock();
        console.log(""+this.userId+" attending" +eventid)
        Meteor.users.update(this.userId, $addToSet: { attending: eventid})

      updateContentStats: (id, stats) ->
        this.unblock()
        model.contentCollection.update(id,{$set: {fbstats: stats}})

    Meteor.users.allow(
      update: (uid, doc, fieldNames, modifier) ->
        return (uid == Meteor.userId() && fieldNames.length == 1 && (fieldNames[0] == "attending" or fieldNames[0] == "geolocation"))

    )

  if (Meteor.isClient)
    require ["FacebookClient","FacebookApiHelpers"], (fb, apiHelpers) ->

      self.fbLoggedin = (fbapi) ->
        #return #hack to not attend events
        fbapi.api("/me/events", (res) -> _.each(res.data, (e) ->
          Meteor.call("importFacebookEvent",e.id, (err,res) ->
            console.log("imported", res)
            if res.event?._id and ! res.alreadyInDB
              console.log("alerting for event", res)

              Alerts.add("eventInsertedMessage", res.event, "success",  {autoHide: 10000, html: true});
              Meteor.users.update(Meteor.userId(), $addToSet: { attending: res.event._id})
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


      self.updateEventStats = (event) ->
        fb.ensureLoggedIn( ->
          fbHelpers.eventStats.run(event, fb, (res) -> console.log("updated event stats", res))
        )

      self.rsvp_confirmed = (event) ->
        return false unless Meteor.user()
        _.contains(Meteor.user().attending, event._id)

      self.rsvp = (eventid,confirm) ->
        console.log("rsvp, evt id:", eventid)
        if (confirm)
          Meteor.users.update(Meteor.userId(), $addToSet: { attending: eventid})
        else
          Meteor.users.update(Meteor.userId(), $pull: { attending: eventid})
        if (true)
          fbConnection = if confirm then "attending" else "maybe"
          fb.ensureLoggedIn( (res) ->
            fb.api.api(model.getContentById(eventid).sourceId+"/"+fbConnection,"POST", (res) -> console.log(res))
          , ["rsvp_event"])
      fb.onLoggedIn(self.fbLoggedin)

      self.getFriendsAttending = (eventId, callback) ->
        fbEventId = model.getContentById(eventId).sourceId
        fqlQuery = "SELECT uid,rsvp_status FROM event_member WHERE eid = " + fbEventId + " AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
        fb.api.api("/fql",{q:fqlQuery}, (res) ->
          callback(_.map(_.filter(res.data, (u) -> u.rsvp_status == "attending"), (attending) -> {fbUid: attending.uid}))
          console.log("loaded friends attending", res)
        )

  return self;