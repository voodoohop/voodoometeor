require ["VoodoocontentModel","FacebookClient"], (model, fb) ->
  Template.likewidget.rendered = (arg1,arg2) ->
   # this.likeLadda = Ladda.create(this.find(".likebutton"))

  Template.likewidget.liked = ->
    console.log("already like helper", res = _.contains(this.likes, Meteor.user()?._id) )
    return res
  Template.likewidget.disabledAttribute = ->
      {disabled: true} if _.contains(this.likes, Meteor.user()?._id)
  Template.likewidget.events
    "click .likebutton": (e, component) ->
      console.log("likewidget clicked",this,e,component)
      component.likeLadda?.start()
      Meteor.call("like", component.data._id, (err, res) -> console.log("likeres", res); component.likeLadda?.stop())
      fb.ensureLoggedIn( ->
        console.log("fbapi: /me/og.likes","POST", {object: Meteor.absoluteUrl(window.location.pathname.substring(1))})
        fb.api.api("/me/og.likes","POST", {object: Meteor.absoluteUrl(window.location.pathname.substring(1))}, (res) ->
          component.likeLadda?.stop()
          console.log(res)
        )
      ,["publish_actions"])

  Template.contentcarousel.items_first_active = ->
    _.map(this.items, (item, index) ->
      return if (index == 0) then _.extend({isActive: true}, item) else item
    )
  Template.contentcarousel.count_up_to = ->
    return null unless this.items?.length
    res=_.map(_.range(this.items.length), (val) ->
      return if (val == 0) then {isActive: true, index: val} else {index: val}
    )
    return res

  Template.contentcarousel.rendered = ->
    console.log("carousel rendered", this)
    node = $(this.firstNode)
    Meteor.setTimeout( ->
      node.carousel('cycle')
    , 5000)

  Template.wallpostform.rendered = ->
    console.log(this.find("button"))
    this.submitLadda = Ladda.create(this.$("button")[0])



  Session.set("delayNextWallPost",Session.get("delayNextWallPost"))
  decrement = ->
    Meteor.setTimeout( ->
      delay = parseInt(Session.get("delayNextWallPost"))
      Session.set("delayNextWallPost", delay-1)
      if (delay > 0)
        decrement()
    , 1000)
    
  if (Session.get("delayNextWallPost"))
    decrement()

  Template.wallpostform.cantPost = ->
    parseInt(Session.get("delayNextWallPost")) > 0

  Template.wallpostform.nextPostDelay = ->
    parseInt(Session.get("delayNextWallPost"))

  Template.wallpostform.events
    "click .submitpost": (event,tmplInstance)->
      inputfield = $(tmplInstance.firstNode).find("input")[0]
      linkURL = inputfield.value
      linkURL = 'http://' + linkURL if (!linkURL.match(/^[a-zA-Z]+:\/\//))
      tmplInstance.submitLadda.start()
      inputfield.value = linkURL
      $.embedly.oembed(linkURL,
        key: 'b5d3386c6d7711e193c14040d3dc5c07'
        query: {width:345}
      ).progress((data) ->
        console.log(data);
        Meteor.call("insertWallPostFromEmbedly", data, (err,res) ->
          console.log("inserted")
          tmplInstance.submitLadda.stop()
          inputfield.value=""
          Session.set("delayNextWallPost",30)
          decrement()
        )
      )
