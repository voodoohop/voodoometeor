define "Config",[], ->
  this.globalconfig = new Meteor.Collection("config")
  if (Meteor.isClient)
    Meteor.subscribe("config")
  if (Meteor.isServer)
    Meteor.publish "config", ->
      globalconfig.find()
  this.current = -> this.globalconfig.findOne()
  this.isInitialized = -> this.globalconfig.find().count() > 0
  return this