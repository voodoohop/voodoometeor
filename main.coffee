
if (Meteor.isServer)
  Meteor.require('nodetime').profile(
    accountKey: 'f6554c48283af492abfcd07d5ad45f584e1fa3e5',
    appName: 'VOODOO METEOR'
  )
  console.log("NodeTime Profiler inited")

require ["EventManager","Embedly"], (eventmanager,embedly) ->

  if (Meteor.isServer)
    #  Meteor.users.remove({})
    #Meteor.publish "user", ->
    #  Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1, virtude: 1}})
    Meteor.publish("userData", ->
      Meteor.users.find({_id: this.userId}, {fields: {attending: 1, services: 1, profile: 1, geolocation: 1}});
    )
    Meteor.publish("userLocation", (query) ->
      Meteor.users.find(query, {fields: {mrlf}});
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

    require ["ContentgridController"] , (contentGridController) ->





      Router.map ->
        this.route 'content',
          path:'/'
          template: 'contentgrid'
          layoutTemplate: 'mainlayout'
          #yieldTemplates:
           # 'filterbar': {to: 'navbar'}

      console.log("configured router")


      Meteor.startup ->
        Handlebars.registerHelper("user", ->
          Meteor.user()
        )

       # console.log("logging in with facebook")
       # Meteor.loginWithFacebook({ requestPermissions: ['email']}, (err) ->
       #   console.log(err)  if err?
       # )


