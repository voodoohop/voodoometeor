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

  Handlebars.registerHelper("conditionalClass", (classname, condition) ->
    res= {}
    if (condition)
      res.class = classname
    res
  )
  Handlebars.registerHelper("responsiveButtons", ->
    _.delay( ->
      Meteor.refreshResponsiveElements();
      console.log("refreshed responsive elements")
    , 200)
    return "responsive-buttons"
  )