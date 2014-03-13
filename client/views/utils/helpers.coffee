Meteor.startup ->
  Handlebars.registerHelper("user", ->
    console.log("user helper")
    Meteor.user()
  )
  Handlebars.registerHelper("cropstring", (string, length, overLengthAppend=null) ->
    return string if string.length <= length
    res = string?.substr(0,length)
    attachOverlength = res.length < string.length and overLengthAppend
    res = res.substr(0,res.lastIndexOf(" "))
    res += overLengthAppend if attachOverlength
    return res
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