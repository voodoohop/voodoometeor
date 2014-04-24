Nodetime.profile({
  accountKey: 'f6554c48283af492abfcd07d5ad45f584e1fa3e5',
  appName: 'Node.js Application'
})
@profiler = Meteor.require('v8-profiler')


require "Config", (config) ->
  console.log("reading config")
  config.globalconfig.remove({})
  if ! config.isInitialized()
    config.globalconfig.insert
      facebook:
        pageaccesstoken: "CAAAAEinyRRYBAGYV8VTy8YJohLuaqFFqmZCVpsGEsY5bxwQf39xyTAyYpjoeC2gfZCrvk1MZBSacdiDAxHA5kGlLMbu0oLCzHkmqQVUc8Vdi98fOEcVd9OKrGpUwrROczZBUMQz5MjHUjGAJRSzIdf1JuGeNnMMinTZBQ1N8NPRYpeGNPpZALf"
        appid: "78013154582"
        appsecret: "e702a69b75c23dc41266d719cec3c408"
      embedly:
        key: "b5d3386c6d7711e193c14040d3dc5c07"
      paypaltoken: "qifucLPH6_c135gdb7OXCHjYFghb4U6xOxWbyelQPoZiAxBdEhqvAD11daW"
  console.log(Roles.getAllRoles().fetch())

  Meteor.users.update({roles: {$exists: false}},{$set:{roles:[]}},{multi: true})
  unless (_.find(Roles.getAllRoles().fetch(), (role) -> role.name == "feature_event"))
    Roles.createRole("feature_event")
  unless (_.find(Roles.getAllRoles().fetch(), (role) -> role.name == "admin_event"))
    Roles.createRole("admin_event")

  if user = Meteor.users.findOne({"profile.name": "Thomas Haferlach"})
    Roles.addUsersToRoles(user._id,["admin_event","feature_event"])
  console.log(Roles.getRolesForUser(Meteor.users.findOne({"profile.name": "Thomas Haferlach"})._id))
  if Meteor.users.findOne({"profile.name": "Laurence Trille"})
    Roles.addUsersToRoles(Meteor.users.findOne({"profile.name": "Laurence Trille"}),["admin_event","feature_event"])
  if Meteor.users.findOne({"profile.name": "Pita Uchoa"})
    Roles.addUsersToRoles(Meteor.users.findOne({"profile.name": "Pita Uchoa"}),["admin_event","feature_event"])

  Meteor.publish(null, ->
    Meteor.roles.find({})
  )