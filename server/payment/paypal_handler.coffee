require ["Config"], (config) ->
  Meteor.startup ->
    Router.map ->
      this.route('paypalPaymentReturn',
        where: 'server'
        path: 'paypalpaymentreturn'
        action: ->
          this.response.writeHead(200, {'Content-Type': 'text/html'});
          this.response.end('');
          console.log(this.request)
          transactionId = this.request.query.tx;
          console.log("got transaction id", transactionId)
          console.log("pp token", config.current().paypaltoken)
          HTTP.call("POST", "https://www.sandbox.paypal.com/cgi-bin/webscr",
            data:
              cmd: "_notify-synch"
              tx: transactionId
              at: config.current().paypaltoken
          , (err, res) ->
            console.log("paypalres",err,res)
          )
      )