
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
        model.contentCollection.update(id,{$set: {fbstats: stats}})#, num_app_users_attending: stats.voodooAttendingCount}})
      featureEvent: (eventid, featured) ->
        console.log("trying to feature event", eventid, this.userId)
        if (Roles.userIsInRole(this.userId,"admin_event"))
          console.log("featuring event", eventid)
          model.contentCollection.update(eventid,{$set:{featured: featured}})
          return true
        else
          return false
      blockContent: (id, blocked) ->
        console.log("trying to block content", id, this.userId)
        if (Roles.userIsInRole(this.userId,"admin_event"))
          #console.log("featuring event", eventid)
          model.contentCollection.update(id, {$set:{blocked: blocked}})
          return true
        else
          return false
      enableList: (id, listEnabled) ->
        #console.log("trying to block content", id, this.userId)
        if (Roles.userIsInRole(this.userId,"admin_event"))
          #console.log("featuring event", eventid)
          model.contentCollection.update(id, {$set:{hasList: listEnabled}})
          return true
        else
          return false

    Meteor.users.allow(
      update: (uid, doc, fieldNames, modifier) ->
        return (uid == Meteor.userId() && fieldNames.length == 1 && (fieldNames[0] == "attending" or fieldNames[0] == "geolocation"))

    )

  if (Meteor.isClient)
    require ["FacebookClient","FacebookApiHelpers"], (fb, apiHelpers) ->

      self.fbLoggedin = (fbapi) ->
        #return #hack to not attend events
        fbapi.api("/me/events", (res) -> _.each(res.data, (e) ->
         if e?.id
          if moment(e.end_time ? e.start_time).diff(moment()) > 0
           Meteor.call("importFacebookEvent",e.id, (err,res) ->
            console.log("imported", res)
            if res.event and ! res.alreadyInDB and ! res.updated
              #console.log("alerting for event", res)

              Alerts.add("eventInsertedMessage", model.getContentById(res.event), "success",  {autoHide: 10000, html: true});
              Meteor.users.update(Meteor.userId(), $addToSet: { attending: res.event._id})
            #Meteor.call("attendEvent", id, (err, res) -> console.log(err,res));
          )
        ))
        return ## hack to not load friends events
        eventProcessCount = 20
        fbapi.api "/me/friends",
          limit: 3000
        , (res) ->
          numProcessing = 0
          friendprocess = (friendlist) ->
            if (eventProcessCount <= 0)
              return
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
                if (eventProcessCount <= 0)
                  return
                numProcessing++
                if (evts.length <= 0)
                  friendprocess(friendlist)
                  return
                #console.log("length before",evts)
                event = evts.shift()
                #console.log("length after",evts)
                if (event?.id?)
                  Meteor.call "importFacebookEvent", event.id, (err,re) ->
                    eventProcessCount--
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
          friends = _.shuffle(res.data)
          console.log("importing for friends",friends)
          friendprocess(friends)


      self.updateEventStats = (event) ->
        #return false #DISABLE TEMPORARILY FOR EASTER
        fb.ensureLoggedIn( ->
          fbHelpers.eventStats.run(event, fb, (res) -> console.log("updated event stats", res))
          console.log("updating comments")
          fbHelpers.eventComments.run(event,fb, (res) -> console.log("updated comments"))
        )



      self.rsvp_confirmed = (event) ->
        return false unless Meteor.user()
        _.contains(Meteor.user().attending, event._id)
      model.registerHelpers
        rsvp_confirmed: -> self.rsvp_confirmed(this)
      self.invite = (fbeventid, friendlist) ->
        console.log "/"+fbeventid+"/invited", {users: _.map(friendlist, (u) -> u.id)}
        fb.api.api("/"+fbeventid+"/invited","POST", {users: _.map(friendlist, (u) -> u.id)}, (fbres) -> console.log("fbeventinvite res:", fbres))
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
            if (confirm)
              fb.api.api("me/voodoohop:attend","POST",
                event: Meteor.absoluteUrl("contentDetail/"+eventid)
                #"fb:explicitly_shared": true
              , (res) -> console.log("fbres",res))
          , ["rsvp_event","publish_actions"])
      fb.onLoggedIn(self.fbLoggedin)

      self.getFriendsAttending = (eventId, callback) ->
        return unless fb.loggedIn
        fbEventId = model.getContentById(eventId).sourceId
        fqlQuery = "SELECT uid,rsvp_status FROM event_member WHERE eid = " + fbEventId + " AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
        fb.api.api("/fql",{q:fqlQuery}, (res) ->
          callback(_.map(_.filter(res.data, (u) -> u.rsvp_status == "attending"), (attending) -> {fbUid: attending.uid}))
          console.log("loaded friends attending", res)
        )

  return self;

