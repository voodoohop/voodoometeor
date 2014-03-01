Meteor.startup ->
  @userPayed = new Meteor.Collection("userPayed")
  if Meteor.isServer
    userPayed.remove({})
    Meteor.publish "userPayed" , -> userPayed.find()
    console.log "get payed data", dta = JSON.parse(Meteor.http.get("http://voodoohop.com/userpayed-json.php?eventid=831").content)
    _.each(dta, (item) ->
      userPayed.upsert({userId: item.userid}, {$set:
        userId: item.userid
        eventId: item.eventid
      })
      console.log("upsert", item)

    )

  else
    Meteor.subscribe "userPayed"
