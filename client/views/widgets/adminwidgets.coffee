
Meteor.startup ->
  require ["VoodoocontentModel"], (model) ->
    RloginTokens = new ReactiveDictionary()
    Router?.map ->
      this.route 'eventticketadmin',
        path: "/admin/eventTicket/:_eventId/"
        data: ->
          eventId = this.params._eventId
          event =  model.getContentById(this.params._eventId)
          console.log(this.params)
          console.log("data:", event)
          mongoop = {}
          mongoop["eventTickets."+this.params._eventId] = {$exists: true}
          usersWithTickets = _.sortBy(Meteor.users.find(mongoop).fetch(), (user) -> user.profile.name.toLowerCase())

          eventTickets = []
          _.each(usersWithTickets, (u) ->

            _.each(u.eventTickets[eventId], (ticket) ->
              eventTickets.push({eventId:eventId,buyerId: u._id, buyerName: u.profile.name, nameOnList: ticket.nameOnList, buyerEmail: null, paymentMethod: ticket.paymentMethod, changedName: ticket.changedName})

              unless (RloginTokens[u._id])
                token = {token: false}
                RloginTokens.add(u._id,token)
                Meteor.call("generateLoginToken",u._id, (err,res) -> RloginTokens[u._id] = res)
            )
          )
          console.log("eventTickets", eventTickets)
          {event, eventTickets}
    Template.eventticketadmin.loginToken = ->
      console.log("logintokenhelper", RloginTokens[this.buyerId])

      RloginTokens[this.buyerId].token

