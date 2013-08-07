

  if (Meteor.isServer)
    #  Meteor.users.remove({})
    Meteor.publish "users", ->
      Meteor.users.find({},{fields: {'profile': 1, services : 1, pecado: 1}})

    console.log("---users---")
    console.log(Meteor.users.find().fetch())

  if (Meteor.isClient)
    require ["ContentgridController"] , (contentGridController) ->

      Meteor.subscribe "users"

      Meteor.Router.add
        '/eventgrid': 'eventgrid'
        '/contentgrid': 'contentgrid'
        '/quiz': 'quiz'
        '/eventdetail/:id': 'eventdetail'
        '*': 'not_found'

      Template.maintemplate.user = Meteor.user

      Meteor.startup ->
        Handlebars.registerHelper("user", ->
          Meteor.user()
        )


