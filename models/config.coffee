define "Config",[], ->
  self = {}
  self.globalconfig = new Meteor.Collection("config")
  if (Meteor.isClient)
    Meteor.subscribe("config")
  if (Meteor.isServer)
    Meteor.publish "config", ->
      self.globalconfig.find()
  self.current = -> self.globalconfig.findOne()
  self.isInitialized = -> self.globalconfig.find().count() > 0
  return self