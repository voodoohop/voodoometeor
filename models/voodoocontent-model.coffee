define "VoodoocontentModel",[], ->
  console.log("loading content model")
  self= {};

  self.contentCollection = new Meteor.Collection("voodoocontent")

  self.contentBlockSize = 35

  self.helpers =
    postedDate: -> moment.parseZone(this.post_date).local().fromNow()
    fullDay: ->
      format = "dddd"
      p = moment.parseZone(this.post_date).local()
      if ! (p.diff(moment().local(),"days") in [0..6])
        format += " D/M"
      p.format(format)
    time: ->
      return "" if (this.only_date)
      moment.parseZone(this.post_date).local().format("HH:mm")
    day: ->
      format = "ddd"
      p = moment.parseZone(this.post_date).local()
      if ! (p.diff(moment().local(),"days") in [0..6])
        format += " D/M"
      p.format(format)
    isFeatured: -> (this.isFeatured == true)
    numlikes: -> this.like_count ? 0
    description: ->
      #console.log("getting description", this.description)
      this.description
    getPicture: ->
      return this.picture_override ? this.picture

  self.contentCollection.helpers self.helpers

  description_reduced: ->
    console.log("reducing", this)
    this.description.substring(0,300)+ "..."





  self.lastItemCount = -> self.cursor?.count() ? 0

  if (Meteor.isClient)

    self.subscribeContent =  (options, callback) ->
      console.log("subscribing to content", options)
      if (options?.details)
        Meteor.subscribe "contentDetail", options, callback
      else
        [Meteor.subscribe("featuredContent", options), Meteor.subscribe("content", options, callback)]

    #Meteor.startup ->
    #  Meteor.subscribe( "featuredContent")
    self.stopDetailSubscription = ->
      console.log("stopped detail subscription")
      self.detailSubscription.stop()
      self.detailSubscription = null
      self.detailId = null
    self.subscribeDetails = (id, callback) ->
      Deps.nonreactive ->
        console.log("model, trying to subscribe to details",id)
        if (self.detailSubscription and id != self.detailId)
          self.stopDetailSubscription()
          #  callback() if (callback?)
        if (id and id != self.detailId)
          self.detailSubscription = self.subscribeContent({query: id, details: true}, callback)
          self.detailId = id
        return self.detailSubscription


  self.lastLimit = 0

  self.getContent = (options) ->
      console.log options
      opts =
        #skip: self.contentBlockSize *  (options?.blockno ? 0)
        limit: if options?.blockno? > 0 then self.lastLimit = (self.contentBlockSize * (options?.blockno ? 0) ) else undefined
        fields: options?.fields
        sort: options?.sort
      q = options?.query ? {}
      console.log("running find on db",q,opts)
      self.cursor = self.contentCollection.find(q, opts)
      return self.cursor

  self.getContentBySourceId = (sourceId) -> self.contentCollection.findOne({sourceId: sourceId})
  self.getContentById = (id) ->
    if (self.detailId != id)
      console.log("not yet subscribed... subscribing",id)
      self.subscribeDetails(id);
    self.contentCollection.findOne(id)

  if (Meteor.isServer)

    self.contentCollection._ensureIndex({type:1, post_date: 1, num_app_users_attending: 1, start_time: 1, sourceId: 1, blocked: 1})
    Meteor.publish "content", (options = {}) ->
      console.log("client subscribed to content", options)
      if (! options.fields? && ! options.details )
        options.fields = { facebookData: 0, description: 0 }
      self.getContent(options)

    Meteor.publish "featuredContent", (options = {}) ->
      console.log("client subscribed to featured content", options)
      options.fields = { facebookData: 0, description: 0 }
      options.blockno = 0
      options.query.featured = true
      self.getContent(options)

    Meteor.publish "contentDetail", (options) ->
      self.getContent(options)
    #Meteor.publish "featuredContent", ->
    #  self.getContent({query: {featured: true}})

    Meteor.methods
      like: (contentId) ->
        if (!this.userId?)
          return false;
        console.log("adding like to ",contentId, "from user", this.userId)
        self.contentCollection.update(contentId, {$addToSet: {likes: this.userId }})
        return true;

  return self
