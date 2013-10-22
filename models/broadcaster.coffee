define "Broadcaster",[], ->

  self = {}
  self.broadcasts = new Meteor.Collection("broadcasts")
  self.broadcasts.allow ->
    insert: (u,d) ->
      true

  if (Meteor.isClient)

    self.receivers = []
    self.registerReceiver = (callback) ->
      self.receivers.push(callback)

    Meteor.autosubscribe( ->
      self.broadcasts.find().observe(
        added: (item) ->
          _.each self.receivers (r) ->
            r item.message
      )
    )

  if (Meteor.isServer)

    Meteor.publish "broadcasts", ->
      self.broadcasts.find()
    self.broadcast = (data) ->
      self.broadcasts.remove({})
      self.broadcasts.insert
        message: data

    Meteor.startup ->
      self.broadcast({heyhey: "hello"})
  return self

