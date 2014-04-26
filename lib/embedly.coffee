#TODO
#refactor all embedly code to use new embedly connection instead of storing in documents

define "Embedly", ["Config","VoodoocontentModel"],  (config, model) ->

  self = {}

  embedlyCollection = new Meteor.Collection("embedlycache")

  self.embedly_key = -> config.current().embedly.key

  self.getEmbedlyData = (params) ->
    return null if params.url.indexOf("://") == -1
    existing = embedlyCollection.findOne(params)
    if (Meteor.isServer and ! existing?)
      data = self.runembedly(params)[0]
      embedlyCollection.insert(_.extend({embedly: data},params))
      return data
    if (Meteor.isClient)
      Meteor.subscribe("embedlyCache",params)
      console.log("embedly subscribed to", params)
    return existing?.embedly

  self.getDefaultDimensions =  (url) ->
    e = self.getEmbedlyData({url:url, "default": true})
    return null unless e
    if e.width
      [e.width,e.height]
    else
      [e.thumbnail_width, e.thumbnail_height]

  createContentItemFromEmbedly = (url, data, additionalParams={}) ->
      return unless data?
      pic = data.thumbnail_url
      if ! pic?
        if data.type =="photo"
          pic = data.original_url
      type = data.type
      type = "video" if type == "rich"
      return unless pic
      post =
        title: data.title ? data.original_url
        description: data.description
        link: url
        type: type
        post_date: moment().toJSON()
        source: "embedly"
        picture: pic
        overrideWidth: data.width
        overrideHeight: data.height
      console.log("created content item from embedly data", post, data)
      return _.extend(post, additionalParams)

  self.getContentItemData = (params, additionalParams={}) ->
    return createContentItemFromEmbedly(params.url,self.getEmbedlyData(params,additionalParams))


  if (Meteor.isServer)

    embedlyCollection._ensureIndex({url:1})
    embedlyCollection._ensureIndex({maxheight:1})
    embedlyCollection._ensureIndex({maxwidth:1})

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

    Meteor.publish("embedlyCache", (params) ->
      self.getEmbedlyData(params)
      embedlyCollection.find(params)
    )


    insertPostFromEmbedly = (data,additionalFields = {}) ->
      model.contentCollection.insert _.extend(createContentItemFromEmbedly(data), additionalFields)



    Meteor.methods(
      insertPostFromLink: (params, additionalFields= {}) ->
        insertPostFromEmbedly(self.getEmbedlyData(params), additionalFields)
      getEmbedlyData: (params)-> self.getEmbedlyData(params)

    )
    model.contentCollection.before.insert( (userId, doc) ->
      if (doc.link?)
        self.getEmbedlyData({url: doc.link, "default": true})
        doc.loadedDefaultEmbedly = true
    )

  self.getCroppedImageUrl = (srcimg, width, height) ->
    "http://i.embed.ly/1/display/crop?height="+height+"&width="+width+"&url="+encodeURI(srcimg)+"&key="+self.embedly_key()


  self.embedParams = {autoplay: true}

  if (Meteor.isClient)
    

    UI.registerHelper("embedly", (options)-> console.log("embedly helper optons",options.hash); self.getEmbedlyData(options.hash))
    UI.registerHelper("embedlyContentItem", (options)->
      console.log("embedlyContentItemData",this, options);
      data = self.getContentItemData(options.hash)
      if data
        model.createContentItem(data)
    )
  return self
