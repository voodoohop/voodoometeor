require ["VoodoocontentModel","ContentItem"], (model, contentItem) ->
  console.log("adding content detail route")
  Meteor.startup ->
   Router?.map ->
    this.route 'contentdetail',
      path: '/contentdetail/:_id'
      #template: 'contentdetail'
      layoutTemplate: 'mainlayout'
      yieldTemplates:
        'contentdetailhead': {to: 'head'}
        'contentdetail': {to: 'contentdetail'}
      #waitOn: ->
      #  console.log("router subscribing to ",this.params._id)
      #  model.getDetails(this.params._id)
      before: ->
        model.subscribeDetails(this.params._id)
      data: ->
        console.log("getting content for:", this.params._id)
        model.getContentById(this.params._id, true)


  Template.contentdetail.helpers(model.helpers)
  Template.contentdetail.helpers(contentItem.helpers)


  Template.contentdetail.friendsAttending = ->
    console.log("checking if we can get facebook friends attending")
    return unless Session.get("fbloggedin") && this.sourceId
    console.log(this)
    fqlQuery = "SELECT uid FROM event_member WHERE eid = " + this.sourceId + " and rsvp_status = 'attending' AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
    console.log(fqlQuery)
    FB.api("/fql",{q:fqlQuery}, (res) ->
      images= _.map(res.data, (e) ->
        "<img src='http://graph.facebook.com/" + e.uid + "/picture'>"
      )
      console.log("loaded profile images")
      Session.set("profileimages",images.join(" "))
    )
  Template.contentdetail.profileimages = ->
    Session.get("profileimages")
