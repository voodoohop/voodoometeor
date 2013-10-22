define "ClientShared",[], ->

  self ={}
  self.sharedData = new Meteor.Collection("sharedData")
  self.sharedData.allow
    insert: (u,d) ->
      true
    update: (u,d) ->
      true


  if (Meteor.isClient)
    Meteor.subscribe("sharedData")

  if (Meteor.isServer)
    self.sharedData.remove({})

    Meteor.publish "sharedData", ->
      self.sharedData.find()

  return self

