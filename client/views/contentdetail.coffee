Meteor.startup ->
  console.log("content detail initing")


  updateHeadData = (data) ->
    SEO.set
      title: data.title
      meta:
        description: data.description
      og:
        title: data.title
        description: data.description




  require ["VoodoocontentModel","ContentItem", "FacebookClient"], (model, contentItem, fb) ->
    console.log("adding content detail route")
    Router?.map ->
      this.route 'contentdetail',
        path: '/contentdetail/:_id'
        #template: 'contentdetail'
        layoutTemplate: 'mainlayout'
        #yieldTemplates:
        #  'contentdetailhead': {to: 'head'}
        #  'contentdetail': {to: 'contentdetail'}
        #waitOn: ->
        #  console.log("router subscribing to ",this.params._id)
        #  model.getDetails(this.params._id)
        waitOn: ->
          console.log("ROUTE BEFORE - subscribing to ",this.params._id)
          model.subscribeDetails(this.params._id)
        data: ->
          #console.log("getting content for:", this.params._id)
          model.getContentById(this.params._id)

        #after: ->
        #  data = this.getData()
        #  console.log("updating header", this, data)



    Template.contentdetail.helpers(model.helpers)
    Template.contentdetail.helpers(contentItem.helpers)


    Template.contentdetail.friendsAttending = ->
      console.log("checking if we can get facebook friends attending")
      if Session.get("fbloggedin") && this.sourceId
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

    $(window).scroll( ->
      $(".detach-on-scroll").each ->
        #console.log($(this).offset())
        if ($(this).offset().top  < $(window).scrollTop())
          $(this).find(".detach-content").addClass("detached")
        else
          $(this).find(".detach-content").removeClass("detached")

    )

