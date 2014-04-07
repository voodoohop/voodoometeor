#TODO
#refactor all embedly code to use new embedly connection instead of storing in documents

define "Embedly", ["Config","VoodoocontentModel"],  (config, model) ->

  self = {}



  embedlyCollection = new Meteor.Collection("embedlycache")

  self.embedly_key = -> config.current().embedly.key

  self.getEmbedlyData = (params) ->
    return null if params.url.indexOf("://") == -1
    existing = embedlyCollection.findOne(params)

    return existing.embedly if existing
    if (Meteor.isServer)
      data = self.runembedly(params)[0]
      embedlyCollection.insert(_.extend({embedly: data},params))
      return data
    if (Meteor.isClient)
      Deps.nonreactive ->
        Meteor.subscribe("embedlyCache",params)
      console.log("embedly subscribed to", params)
      return null


  if (Meteor.isServer)

    embedlyCollection._ensureIndex({url:1,maxwidth:1, maxheight:1})
    key = self.embedly_key()
    embedly = Meteor.require('embedly')
    util = Meteor.require('util')

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
      console.log("running embedly", params)
      return Meteor.sync( (done) ->
        embedlyapi.oembed _.clone(params), (err, result) ->
          done(null, result)
      ).result

    subscribedParams = {}

    Meteor.publish("embedlyCache", (params) ->
      connId = this.connection.id
      if ! subscribedParams[connId]
        subscribedParams[connId] = []
        this.connection.onClose( -> delete subscribedParams[connId])
      unless _.findWhere(subscribedParams[connId], params)
        subscribedParams[connId].push(params)
      self.getEmbedlyData(params)
      console.log("embedly find",{$or: subscribedParams[connId]})
      embedlyCollection.find({$or: subscribedParams[connId]})
    )

    Meteor.methods(
      getEmbedlyData: (params)-> self.getEmbedlyData(params)

      prepareMediaEmbeds: (options) ->
        this.unblock()
        return unless options.id
        content = model.contentCollection.findOne({_id: options.id, embedlyData: { $not: { $elemMatch: options.params }} })
        console.log("preparing embeds for content", options, content)
        return unless content?.link?
        self.getEmbedlyData(_.extend({url:content.link},options.params))

      prepareEmbedsForComment: (comment, params) ->
        #this.unblock()
        embedlyData = self.getEmbedlyData(params)
        Comment._collection.update(comment._id, {$set: {"attachment.embedlyData": embedlyData}})
    )

  self.getCroppedImageUrl = (srcimg, width, height) ->
    "http://i.embed.ly/1/display/crop?height="+height+"&width="+width+"&url="+encodeURI(srcimg)+"&key="+self.embedly_key()


  self.embedParams = {autoplay: true}

  if (Meteor.isClient)


    UI.registerHelper("embedly", (options)-> console.log("embedly helper optons",options.hash); self.getEmbedlyData(options.hash))

  return self
