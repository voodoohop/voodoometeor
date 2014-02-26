require ["VoodoocontentModel","FacebookClient"], (model, fb) ->
  Template.likewidget.rendered = (arg1,arg2) ->
    this.likeLadda = Ladda.create(this.find(".likebutton"))

  Template.likewidget.liked = ->
    console.log("already like helper", res = _.contains(this.likes, Meteor.user()?._id) )
    return res
  Template.likewidget.events
    "click .likebutton": (e, component) ->
      console.log("likewidget clicked",this,e,component)
      component.likeLadda.start()
      Meteor.call("like", component.data._id, (err, res) -> console.log("likeres", res); component.likeLadda.stop())
      fb.ensureLoggedIn( ->
        fb.api.api("/me/og.likes","POST", {object: Meteor.absoluteUrl(window.location.pathname)}, (res) ->
          component.likeLadda.stop()
          console.log(res)
        )
      ,["publish_actions"])