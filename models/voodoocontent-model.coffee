define "VoodoocontentModel",[], ->

  self= {};

  self.contentCollection = new Meteor.Collection("voodoocontent")

  self.contentBlockSize = 5

  self.helpers =
    postedDate: -> moment(new Date(this.post_date)).fromNow()
    day: ->
      format = "ddd"
      p = moment(new Date(this.post_date))
      if ! (p.diff(moment(),"days") in [0..6])
        format += " D/M"
      p.format(format)
    isFeatured: -> (this.isFeatured == true)
    numlikes: -> this.like_count ? 0
    description: ->
      this.description

  description_reduced: ->
    console.log("reducing", this)
    this.description.substring(0,300)+ "..."

  self.subscribeContent =  (options, callback) ->
    console.log("subscribing to content", options)
    if (options?.details)
      Meteor.subscribe "contentDetail", options, callback
    else
      Meteor.subscribe "content", options, callback




  self.lastItemCount = -> self.cursor?.count() ? 0

  if (Meteor.isClient)
    #Meteor.startup ->
    #  Meteor.subscribe( "featuredContent")

    self.subscribeDetails = (id, callback) ->
      if (self.detailSubscription and id != self.detailId)
        self.detailSubscription.stop()
        self.detailSubscription = null
        self.detailId = null
        #if (id == null)
        #  callback() if (callback?)
      if (id)
        self.detailSubscription = self.subscribeContent({query: id, details: true}, callback)
        self.detailId = id


  self.lastLimit = 0

  self.getContent = (options) ->
      console.log options
      opts =
        #skip: self.contentBlockSize *  (options?.blockno ? 0)
        limit: self.lastLimit = (self.contentBlockSize * (options?.blockno ? 0) )
        fields: options?.fields
        sort: options?.sort
      q = options?.query ? {}
      console.log("running find on db",q,opts)
      self.cursor = self.contentCollection.find(q, opts)
      return self.cursor

  self.getContentBySourceId = (sourceId) -> self.contentCollection.findOne({sourceId: sourceId})
  self.getContentById = (id) ->
    if (self.detailId != id)
      self.subscribeDetails(id);
    self.contentCollection.findOne(id)

  if (Meteor.isServer)

    self.contentCollection._ensureIndex({type:1, post_date: 1, num_app_users_attending: 1})
    Meteor.publish "content", (options = {}) ->
      console.log("client subscribed to content", options)
      if (! options.fields? && ! options.details )
        options.fields = { facebookData: 0, description: 0 }
      self.getContent(options)
    Meteor.publish "contentDetail", (options) ->
      self.getContent(options)
    #Meteor.publish "featuredContent", ->
    #  self.getContent({query: {featured: true}})


  return self
