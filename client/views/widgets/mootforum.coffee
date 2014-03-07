Template.mootForum.rendered = ->
  console.log("mootForum created", this)
  #console.log
  #  url: Meteor.absoluteUrl(location.pathname)+":flat"
  $(this.find(".mootForum")).moot
    url: location.pathname+":flat"

