emailColl = new Meteor.Collection("emails")

if (Meteor.isServer)
  Meteor.methods
    "blacklistEmail": (email) ->
      emailColl.insert({email: email, blacklisted: true})
      return true
else
  Router?.map ->
    this.route("blacklistemail",
      path: "/remove"
      template: "blacklistemail"
      layoutTemplate: 'mainlayout'
      action: ->
        console.log(this.params)
        this.render()
        Meteor.call("blacklistEmail", this.params.email, (err, res) -> console.log("blacklistEmail", err, res))
    )