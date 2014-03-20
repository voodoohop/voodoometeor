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
        fb.api.api("/me/og.likes","POST", {object: Meteor.absoluteUrl(window.location.pathname.substring(1)),  "fb:explicitly_shared": true}, (res) ->
          component.likeLadda?.stop()
          console.log(res)
        )
      ,["publish_actions"])