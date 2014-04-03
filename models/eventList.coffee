

@eventList = new Meteor.Collection("eventList")
if (Meteor.isServer)
  Meteor.publish("eventList", -> eventList.find())
  console.log("registering event list adding function")
  Meteor.methods(
    "addNameToEventList": (eventid, name, email) ->
      eventList.insert(
        eventId: eventid
        name: name
        email: email
      )
      return true
  )

#if (Meteor.isClient)
 #Meteor.subscribe("eventList")
 #eventList.before.insert( (userId, doc) ->
 # console.log("name inserted",userId,doc)
 # alert("name inserted"+userId+doc)

Meteor.eventList = eventList
