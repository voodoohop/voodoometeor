Meteor.startup ->
  Handlebars.registerHelper("user", ->
    console.log("user helper")
    Meteor.user()
  )
  Handlebars.registerHelper("cropstring", (string, length) ->
    string.substr(0,length)
  )