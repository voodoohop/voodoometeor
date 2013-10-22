

  if (Meteor.isServer)
    #  Meteor.users.remove({})
    Meteor.publish "users", ->
      Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1, virtude: 1}})

  if (Meteor.isClient)
    require ["ContentgridController"] , (contentGridController) ->

      Meteor.subscribe "users"

      Router.map ->
        this.route 'contentgrid'


      console.log("configured router")
      Template.maintemplate.user = Meteor.user

      Meteor.startup ->
        Handlebars.registerHelper("user", ->
          Meteor.user()
        )

       # console.log("logging in with facebook")
       # Meteor.loginWithFacebook({ requestPermissions: ['email']}, (err) ->
       #   console.log(err)  if err?
       # )


