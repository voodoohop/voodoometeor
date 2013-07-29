define "Config",[], ->
  globalconfig = new Meteor.Collection("config")
  if (Meteor.isClient)
    Meteor.subscribe("config")
  if (Meteor.isServer)
    Meteor.publish "config", ->
      globalconfig.find()
  globalconfig.current = -> globalconfig.findOne()
  globalconfig.isInitialized = -> globalconfig.find().count() > 0
  return globalconfig