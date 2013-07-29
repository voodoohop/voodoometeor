
console.log "loading model"
require "VoodooeventModel" , (eventGridModel) ->
  console.log "loaded model"

  if (Meteor.isServer)
    @Future = Npm.require('fibers/future');
    if eventGridModel.getAllEventsForList().count() is 0
      Meteor.methods(
        #EventsModel.insert({name: "Test"})
        insertJSONfile("server/eventlist.json", eventGridModel.meteorCollection)
      )


if (Meteor.isClient)
  require "EventgridController" , (eventGridController) ->

if (Meteor.isClient)
  Meteor.startup ->
     console.log("startup")

  Meteor.Router.add
    '/eventgrid': 'eventgrid'
    '/eventdetail/:id': 'eventdetail'
    '*': 'not_found'


