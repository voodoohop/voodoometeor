
if (Meteor.isClient)
  Template.waitpage.rendered = ->
    $("#countdown").countdown({until:  new Date(2013, 7, 9, 17) })
