define "VoodooeventModel",[], ->

  self= this;

  this.meteorCollection =  new Meteor.Collection("events")

  this.getAllEvents = (params) -> meteorCollection.find({isvoodoo:"1"})#, {fields: desiredfields})

  this.getAllEventsForList = -> this.getAllEvents({name:1, imgsrc:1, isvoodoo:1})

  this.getEventDetails = (id) -> meteorCollection.find(id)

  if (Meteor.isServer)

    Meteor.publish "allevents", (desiredfields) ->
      console.log("client subscribed to allevents")
      self.getAllEvents(desiredfields)

    Meteor.publish "eventdetails", (id) ->
      console.log("client subscribed to eventdetails, id:"+id)
      self.getEventDetails(id)
  if (Meteor.isClient)
    self.alleventsubscription = Meteor.subscribe "allevents"


  return this