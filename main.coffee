

  if (Meteor.isServer)
    #  Meteor.users.remove({})
    Meteor.publish "users", ->
      Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1, virtude: 1}})

    Meteor.headly.config(
      console.log("headly configured")
      tagsForRequest: (req) ->
        return '<meta property="og:title" content="VOODOOHOP" />'
    )
  if (Meteor.isClient)
    require ["ContentgridController"] , (contentGridController) ->

      Meteor.subscribe "users"

      Meteor.Router.add
        '/eventgrid': 'eventgrid'
        '/contentgrid': 'contentgrid'
        '/quiz': 'quiz'
        '/waitpage': 'waitpage'
        '/eventdetail/:id': 'eventdetail'
        '*': 'not_found'

      Template.maintemplate.user = Meteor.user

      Meteor.startup ->
        Handlebars.registerHelper("user", ->
          Meteor.user()
        )

       # console.log("logging in with facebook")
       # Meteor.loginWithFacebook({ requestPermissions: ['email']}, (err) ->
       #   console.log(err)  if err?
       # )


