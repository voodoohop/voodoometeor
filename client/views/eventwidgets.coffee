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
    $("#fb_invite_button").fSelector
      onPreStart: ->
        fb.ensureLoggedIn()
      onSubmit: (response) ->
        alert(response)