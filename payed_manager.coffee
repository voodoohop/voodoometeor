Meteor.startup ->
  require ["VoodoocontentModel"], (model) ->
    if Meteor.isServer
      Meteor.methods
        "createUserWithTickets":  (fullname, email, eventid, ticketno, paymentMethod=null) ->
          console.log("createUserWithTickets2", fullname, paymentMethod)
          user = Meteor.users.findOne({"emails.address": email})
          unless user
            Accounts.createUser({profile:{name: fullname}, email: email})
            user = Meteor.users.findOne({"emails.address": email})
            console.log("created user", fullname)

          unless user.profile?.name?
            Meteor.users.update({"emails.address": email}, {$set: {profile:{name: fullname}}})
          mongoop = {}
          console.log("user:", user)
          existingTickets = user.eventTickets["#{eventid}"]
          existingTicketCount = existingTickets?.length
          if (!existingTicketCount)
            existingTicketCount = 0
          console.log("already existing", existingTicketCount, ticketno)
          if (existingTicketCount >= ticketno)
            return
          mongoop["#{eventid}"] = _.map([(existingTicketCount+1)..ticketno], (i) -> {nameOnList: (if i == 1 then fullname else null), price: null, ticketType: null, paymentMethod: paymentMethod})
          _.extend(mongoop["#{eventid}"], existingTickets)
          console.log("updating tickets ", email, mongoop["#{eventid}"])
          Meteor.users.update({"emails.address": email}, {$set: {eventTickets: mongoop}})
          return Meteor.users.findOne({"emails.address": email})
      #dta = JSON.parse(Meteor.http.get("http://voodoohop.com/userpayed-json.php?eventid=831").content)

      #eventid = model.getContentBySourceId("249217818582966")._id
      #_.each(dta, (user) ->
      #  Meteor.call("createUserWithTickets",user.name, user.email, eventid,user.quantity,"paypal", (err,res) -> console.log(res))
      #)


      namesAndEmails = _.map(_.filter(moippayments.split("\t"), (v,k) -> k % 6 == 0), (v,k) ->
        v.trim()
        nameandemail = v.trim().split(" ")
        email = nameandemail.pop().trim()
        name = nameandemail.join(" ").trim()
        return {name, email}
      )
      data = _.map(_.countBy(namesAndEmails, (i) -> i.name+","+i.email), (v,k) -> {name: k.split(",")[0], email: k.split(",")[1], count: v})
      _.each(data, (user) ->
        #console.log "createUserWithTickets",user.name, user.email, "2tFkF3j7CgN5K8EFy",user.count
        Meteor.call("createUserWithTickets",user.name, user.email, eventid, user.count, "MoIP", (err,res) -> console.log(res))
      )