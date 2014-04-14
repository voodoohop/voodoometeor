Meteor.startup ->
  Meteor.users.helpers
    hasTicketsFor: (event) ->
      return this.eventTickets?[event._id]?.length
  define "EventticketManager", ["VoodoocontentModel"], (model) ->
    self = {}
    if Meteor.isServer
      self.addTicketsToUser = (eventid, user, ticketno, paymentMethod= null) ->
        mongoop = {}
        console.log("adding tickets to user:", user, ticketno)
        existingTickets = user.eventTickets["#{eventid}"]
        existingTicketCount = existingTickets?.length
        if (!existingTicketCount)
          existingTicketCount = 0
        console.log("already existing", existingTicketCount, ticketno)
        #if (existingTicketCount >= ticketno)
        #  return
        mongoop["#{eventid}"] = []
        mongoop["#{eventid}"].push(existingTickets)
        mongoop["#{eventid}"].push(_.map([(existingTicketCount+1)..ticketno+existingTicketCount], (i) -> {nameOnList: (if i == 1 then user.profile?.name else null), price: null, ticketType: null, paymentMethod: paymentMethod}))

        console.log("updating tickets ", user._id, mongoop["#{eventid}"])
        Meteor.users.update(user._id, {$set: {eventTickets: mongoop}})


      self.createUserWithTickets =  (fullname, email, eventid, ticketno, paymentMethod=null) ->
          console.log("createUserWithTickets2", fullname, paymentMethod)
          user = Meteor.users.findOne({"emails.address": email})
          unless user
            Accounts.createUser({profile:{name: fullname}, email: email})
            user = Meteor.users.findOne({"emails.address": email})
            console.log("created user", fullname)

          unless user.profile?.name?
            Meteor.users.update({"emails.address": email}, {$set: {profile:{name: fullname}}})
          self.addTicketsToUser(user,ticketno)
          return Meteor.users.findOne({"emails.address": email})
    return self
  #dta = JSON.parse(Meteor.http.get("http://voodoohop.com/userpayed-json.php?eventid=831").content)

      #eventid = model.getContentBySourceId("249217818582966")._id
      #_.each(dta, (user) ->
      #  Meteor.call("createUserWithTickets",user.name, user.email, eventid,user.quantity,"paypal", (err,res) -> console.log(res))
      #)


      #namesAndEmails = _.map(_.filter(moippayments.split("\t"), (v,k) -> k % 6 == 0), (v,k) ->
      #  v.trim()
      #  nameandemail = v.trim().split(" ")
      #  email = nameandemail.pop().trim()
      #  name = nameandemail.join(" ").trim()
      #  return {name, email}
      #)
      #data = _.map(_.countBy(namesAndEmails, (i) -> i.name+","+i.email), (v,k) -> {name: k.split(",")[0], email: k.split(",")[1], count: v})
      #_.each(data, (user) ->
      #  #console.log "createUserWithTickets",user.name, user.email, "2tFkF3j7CgN5K8EFy",user.count
      #  Meteor.call("createUserWithTickets",user.name, user.email, eventid, user.count, "MoIP", (err,res) -> console.log(res))
      #)
  require ["EventticketManager"], (ticketManager) ->