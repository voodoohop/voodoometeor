
if (Meteor.isClient)
  require "ContentgridController" , (eventGridController) ->

if (Meteor.isClient)
  Meteor.startup ->
     console.log("startup")

  Meteor.Router.add
    '/eventgrid': 'eventgrid'
    '/contentgrid': 'contentgrid'
    '/quiz': 'quiz'
    '/eventdetail/:id': 'eventdetail'
    '*': 'not_found'

