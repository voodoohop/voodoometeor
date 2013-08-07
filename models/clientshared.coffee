define "ClientShared",[], ->

  self = this
  this.sharedData = new Meteor.Collection("sharedData")
  self.sharedData.allow
    insert: (u,d) ->
      true
    update: (u,d) ->
      true


  if (Meteor.isClient)
    Meteor.subscribe("sharedData")

  if (Meteor.isServer)
    this.sharedData.remove({})

    Meteor.publish "sharedData", ->
      self.sharedData.find()

  return this

