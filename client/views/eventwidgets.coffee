require ["EventManager","VoodoocontentModel","FacebookClient"], (eventManager, model, fb) ->
  console.log("registering event widgets")
  Template.eventtoolbar.events
    'click .rsvp_decline': () ->
      console.log("rsvp_decline click")
      eventManager.rsvp(this._id, false)
    'click .rsvp_attend': () ->
      console.log("rsvp_attend click")
      eventManager.rsvp(this._id, true)
  Template.eventdate.day = model.helpers.day

  Template.eventtoolbar.rendered = ->


  Template.event_genderratio.ratio = ->
    return unless this.stats?
    "" + Math.round(this.stats.genderRatio * 100) + "%"
  Template.event_voodooratio.ratio = ->
    return unless this.stats?
    "" + Math.round(this.stats.voodooRatio * 100) + "%"


  Template.event_friends.created = ->
    console.log("event_friends template CREATED", this)

    this.data = {} unless this.data?
    instData = this.data

    instData.RfriendsAttending = new ReactiveObject(["friends"])
    instData.loadingFriendsAttending = false

    Template.event_friends.profileImages = ->
      eventId = this._id
      console.log("checking if we can get facebook friends attending", eventId)
      return unless eventId
      unless instData.loadingFriendsAttending
        instData.loadingFriendsAttending = true
        fb.onLoggedIn ->
            eventManager.getFriendsAttending(eventId, (attending) -> instData.RfriendsAttending.friends = attending)


      if instData.RfriendsAttending.friends
         _.map(instData.RfriendsAttending.friends, (u) -> "http://graph.facebook.com/" + u.fbUid + "/picture")
      else
        null