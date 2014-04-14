require ["VoodoocontentModel","PaypalIPN"], (model, paypalIPN) ->
  Meteor.startup ->
    Router.map ->
      this.route('paypalpaymentreturn',
        path: 'paypalpaymentreturn'
        template: 'paypalpaymentreturn'
        action: ->
          transactionId = this.params.tx;
          console.log(this.params)
          console.log("paypal transaction id:",transactionId, Meteor.user())
          this.render()
        data: ->
          transaction = paypalIPN.findByTransactionId(this.params.tx)
          event = model.getContentById(this.params.item_number)
          console.log("transaction, event, user", transaction, event, Meteor.user())
          if (Meteor.user() and transaction and event)
            console.log("consuming paypal purchase",transaction)
            Meteor.call("consumePaypalPurchase", event._id, transaction.txn_id, (err,res) ->
              console.log("consume purchase res", err, res)
            )
          {event: event, transaction: transaction}
      )

