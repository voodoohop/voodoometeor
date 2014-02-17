
console.log("initing main")

require "VoodoocontentModel", (model) ->
  console.log("got model")

  require ["EventManager","Embedly"], (eventmanager,embedly) ->
    console.log("loaded eventmanager and embedly")
    if (Meteor.isServer)
      #  Meteor.users.remove({})
      #Meteor.publish "user", ->
      #  Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1, virtude: 1}})
      Meteor.publish("userData", ->
        Meteor.users.find({_id: this.userId}, {fields: {attending: 1, services: 1, profile: 1, geolocation: 1}});
      )
      Meteor.publish("userLocation", (query) ->
        Meteor.users.find(query, {fields: {profile:1, geolocation: 1, "services.facebook.id": 1}});
      )
      ## hack until we manage to set userId on server
      #Meteor.publish("users", ->
      #  Meteor.users.find({});
      #)

    if (Meteor.isClient)

      Hooks.init()  #user login/logout hooks

      Meteor.autosubscribe( ->
        Meteor.subscribe "userData"
        Meteor.subscribe "users"
      )



