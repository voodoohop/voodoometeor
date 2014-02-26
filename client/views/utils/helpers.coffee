Meteor.startup ->
  Handlebars.registerHelper("user", ->
    console.log("user helper")
    Meteor.user()
  )
  Handlebars.registerHelper("cropstring", (string, length) ->
    string?.substr(0,length)
  )

  Handlebars.registerHelper("conditionalAttr", (tagname, condition) ->
    res = {}
    res[tagname] = true if condition
    res
  )