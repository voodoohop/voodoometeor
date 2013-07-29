require "Config",  (config) ->

  if (Meteor.isServer)
    embedly_key = config.current().embedly.key
    embedly = Meteor.require('embedly')
    util = Meteor.require('util')
    #console.log(embedly)
    embedlyapi = Meteor.sync( (done) ->
      new embedly {key: embedly_key}, (err, api) ->
        if (!!err)
          console.error('Error creating Embedly api')
          console.error(err.stack, api)
          done(err,null)
        else
          done(null,api)
      ).result
    Meteor.methods
      embedly: (params) ->
        return Meteor.sync( (done) ->
          embedlyapi.oembed params, (err, result) ->
            console.log(result)
            done(null, result)
          ).result



  #if (Meteor.isClient)
  #  Meteor.methods
  #    embedly: (params) ->
  #      console.log("called embedly method stub")
  #      return "result"