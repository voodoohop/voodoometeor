define "Embedly", "Config",  (config) ->
  self = {}

  self.embedly_key = -> config.current().embedly.key
  if (Meteor.isServer)
    key = self.embedly_key()
    embedly = Meteor.require('embedly')
    util = Meteor.require('util')
    #console.log(embedly)
    this.embedlyapi = Meteor.sync( (done) ->
      new embedly {key: key}, (err, api) ->
        if (!!err)
          console.error('Error creating Embedly api')
          console.error(err.stack, api)
          done(err,null)
        else
          done(null,api)
      ).result

    self.runembedly =  (params) ->
      return Meteor.sync( (done) ->
        embedlyapi.oembed _.clone(params), (err, result) ->
          console.log(result)
          done(null, result)
      ).result

  #  Meteor.methods
  #    embedly: (params) ->
  #       runembedly(params)
  self.getCroppedImageUrl = (srcimg, width, height) ->
    "http://i.embed.ly/1/display/crop?height="+height+"&width="+width+"&url="+encodeURI(srcimg)+"&key="+self.embedly_key()
  return self
  #if (Meteor.isClient)
  #  Meteor.methods
  #    embedly: (params) ->
  #      console.log("called embedly method stub")
  #      return "result"