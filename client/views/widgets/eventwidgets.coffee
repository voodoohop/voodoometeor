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
        link: Meteor.absoluteUrl(Router.path("contentdetail", {_id: this._id}))+"?_escaped_fragment_="
        caption: 'An example caption'
      , (res) -> console.log(res));



  Template.event_genderratio.ratio = ->
    return unless this.fbstats?
    "" + Math.round(this.fbstats.genderRatio * 100) + "%"
  Template.event_voodooratio.ratio = ->
    return unless this.fbstats?
    "" + Math.round(this.fbstats.voodooRatio * 100) + "%"


  Template.updateticketinfo.eventTickets = ->
    eventid = this.contentItem._id
    tickets = Meteor.user().eventTickets?[eventid]
    if tickets
      console.log "eventTickets", res = _.map(tickets, (v,k) -> _.extend({index: k+1, eventId: eventid, buttonState: new ReactiveObject({disabled: true})},v))
      res
    else
      null

  Template.updateticketinfo.inputFailed = ->
    console.log("inputFailed",this)

  Template.ticketlistname.rendered = ->
    console.log("ticketlistname created", this, $("#listname_input_"+this.data.index))
    $("#listname_input_"+this.data.index).jqBootstrapValidation()

  Template.ticketlistname.events
    "change, keyup input": (e) ->
      console.log(this)
      this.buttonState.disabled = $(e.target).jqBootstrapValidation("hasErrors")
    "click .savebutton": (e) ->
      console.log("saving name",this.index - 1, $("#listname_input_"+this.index).val())
      Meteor.call("updateTicketName", this.eventId, this.index - 1, $("#listname_input_"+this.index).val())

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
              console.log("fb logged in, calling eventmanager to get friends")
              eventManager.getFriendsAttending(eventId, (attending) -> component.RfriendsAttending.friends = attending)


        if component.RfriendsAttending.friends
          _.map(component.RfriendsAttending.friends, (u) ->
            image: "http://graph.facebook.com/" + u.fbUid + "/picture"
            name: u.name
            fbid: u.fbUid
          )

    Template.featureeventwidget.events
      'click button': ->
        console.log("featuring event", this)
        Meteor.call("featureEvent", this._id, !this.featured, (err,res) -> console.log(err,res))

    Template.blockcontentwidget.events
      'click button': ->
        console.log("blocking event", this)
        Meteor.call("blockContent", this._id, !this.blocked, (err,res) -> console.log(err,res))

    listHelperState = new ReactiveObject(["name","email","validated","notvalidated","lastSubmitted"])
    listHelperLadda = null;
    listHelperState.rendered =
      #listHelperLadda = Ladda.create(this.find(".submitbutton"))

    listHelperState.notvalidated = true
    Template.listhelper.events
      "change, keyup .listname,.listemail": (e) ->
        name = $(".listname").val()
        email = $(".listemail").val()
        console.log("name,email",name,email)
        listHelperState.name = name
        listHelperState.email = email
        listHelperState.validated = name.indexOf(" ") > 0 and email.indexOf("@") > 0
        listHelperState.notvalidated = ! listHelperState.validated
      "click button": ->
        console.log("submitting", listHelperState)
        if (listHelperState.validated)
          listHelperState.validated = false
          console.log("addNameToEventList",this._id, listHelperState.name, listHelperState.email)
          Meteor.call("addNameToEventList",this._id, listHelperState.name, listHelperState.email, (err, res) ->
            console.log("server res",err,res)
            listHelperState.lastSubmitted = listHelperState.name
            Alerts.add("listsubmitted", listHelperState.name, "success",  {autoHide: 10000, html: true});
            listHelperState.name=""
            listHelperState.email=""
            $(".listname").val("")
            $(".listemail").val("")
            listHelperState.validated = false
          )
    Template.listhelper.state = listHelperState



