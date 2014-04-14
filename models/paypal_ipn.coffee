define "PaypalIPN",["EventticketManager"], (ticketManager) ->
  self = {
    paypalIPNcoll: new Meteor.Collection("paypalIPN")
  }
  Router.map ->
          this.route('paypal_ipn',
            where: 'server'
            path: 'paypal_ipn'
            action: ->
              console.log("paypal request",this.request)
              self.paypalIPNcoll.insert(this.request.body)
              this.response.writeHead(200, {'Content-Type': 'text/html'});
              this.response.end('<html><body>thanks</body></html>');
          )

  if Meteor.isServer
    self.paypalIPNcoll.before.insert((userId, doc) ->
      #for single purchases paypal puts quantity 0
      if (parseInt(doc.quantity)==0)
        doc.quantity = 1
        doc._id = doc.txn_id
    )
    Meteor.publish("paypalIPN", (txnid) ->
      self.paypalIPNcoll.find({txn_id: txnid})
    )
    Meteor.methods(
      "consumePaypalPurchase": (eventid, txnid) ->
        return {success: false, reason:"noUser"} unless this.userId
        txn = self.paypalIPNcoll.findOne({txn_id: txnid})
        return {success: false, reason:"noTransactionFound_"+txnid} unless txn
        if (txn.consumed)
          console.log("already consumed purchase",txn.txn_id)
          return {success: false, reason:"transactionAlreadyConsumed_"+txnid}
        ticketManager.addTicketsToUser(eventid, Meteor.users.findOne(this.userId), parseInt(txn.quantity),"paypal")
        self.paypalIPNcoll.update({txn_id:txnid},{$set:{consumed: this.userId}})
        return true
    )
  if Meteor.isClient
    self.findByTransactionId = (txnid) ->
      Meteor.subscribe("paypalIPN", txnid)
      self.paypalIPNcoll.findOne({txn_id: txnid})
  return self


require ["PaypalIPN"], (paypalIPN) ->