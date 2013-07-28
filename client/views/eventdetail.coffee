require "VoodooeventModel", (eventModel) ->

  eventid =  -> Meteor.Router.args()[0]

  Template.eventdetail.helpers
    _id: ->  eventid()

    voodooevent: ->
        console.log("getting event details for "+eventid())
        eventModel.getEventDetails(eventid())

