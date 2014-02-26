require ["EventManager","VoodoocontentModel","FacebookClient"], (eventManager, model, fb) ->
  console.log("registering event widgets")
  Template.eventtoolbar.events
    'click .rsvp_decline': () ->
      console.log("rsvp_decline click")
      eventManager.rsvp(this._id, false)
    'click .rsvp_attend': () ->
      console.log("rsvp_attend click")
      eventManager.rsvp(this._id, true)
    'click .facebook_share': ->
      FB.ui(
        method: 'feed'
        link: Meteor.absoluteUrl(Router.path("contentDetail", {_id: this._id}))+"?_escaped_fragment_="
        caption: 'An example caption'
      , (res) -> console.log(res));
  Template.eventdate.day = model.helpers.day

  Template.eventtoolbar.eventInviteData = (arg1) ->
    console.log("eventInviteData",this)
    {minimized: true, event: this}

  Template.eventtoolbar.rendered = ->


  Template.event_genderratio.ratio = ->
    return unless this.fbstats?
    "" + Math.round(this.fbstats.genderRatio * 100) + "%"
  Template.event_voodooratio.ratio = ->
    return unless this.fbstats?
    "" + Math.round(this.fbstats.voodooRatio * 100) + "%"


  Template.event_friends.created = ->
    console.log("event_friends template CREATED", this)

    #this.instData = {} unless this.data?


    this.RfriendsAttending = new ReactiveObject(["friends"])
    this.loadingFriendsAttending = false
    component = this

    Template.event_friends.profiles = ->
      if (Meteor.RwindowSize.width > 640)
        eventId = this._id
        console.log("checking if we can get facebook friends attending", eventId)
        return unless eventId
        if ! component.RfriendsAttending.friends and ! component.loadingFriendsAttending
          component.loadingFriendsAttending = true
          fb.onLoggedIn ->
              eventManager.getFriendsAttending(eventId, (attending) -> component.RfriendsAttending.friends = attending)


        if component.RfriendsAttending.friends
          _.map(component.RfriendsAttending.friends, (u) ->
            image: "http://graph.facebook.com/" + u.fbUid + "/picture"
            name: u.name
            fbid: u.fbUid
          )
