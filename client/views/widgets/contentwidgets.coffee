require ["FacebookClient"], (fb) ->
  Template.likewidget.rendered = (arg1,arg2) ->
    console.log("likewidget rendered",this,arg1,arg2)
    console.log this.find(".likebutton")
    this.likeLadda = Ladda.create(this.find(".likebutton"))

  Template.likewidget.events
    "click .likebutton": (e, component) ->
      console.log("likewidget clicked",this,e,component)
      component.likeLadda.start()
      fb.ensureLoggedIn( ->
        fb.api.api("/me/og.likes","POST", {object: Meteor.absoluteUrl(window.location.pathname)}, (res) ->
          component.likeLadda.stop()
          console.log(res)
        )
      ,["publish_actions"])