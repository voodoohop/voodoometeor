define "VoodoocontentModel",["Embedly"], (embedly) ->

  self= {};

  self.contentCollection = new Meteor.Collection("voodoocontent")

  self.contentBlockSize = 10

  self.helpers =
    postedDate: -> moment(new Date(this.post_date)).fromNow()
    day: ->
      format = "dddd"
      p = moment(new Date(this.post_date))
      if ! (p.diff(moment(),"days") in [0..6])
        format += " D/M/YY"
      p.format(format)
    isFeatured: -> (this.isFeatured == true)
    numlikes: -> this.like_count ? 0
    description: ->
      self.subscribeDetails(this._id)
      this.description

  description_reduced: ->
    console.log("reducing", this)
    this.description.substring(0,300)+ "..."

  self.subscribeContent = (options, callback) ->
    Meteor.subscribe "content", options, callback

  self.lastItemCount = -> self.cursor?.count() ? 0
  self.subscribeDetails = (id, callback) ->
    if (Meteor.isClient)
      self.subscribeContent({query: id, details: true}, callback)

  #self.subscribeDetailsIronRouter = (id, callback) ->
  #  if (Meteor.isClient)
  #    self.subscribeContentIronRouter({query: id, details: true}, callback)
  #self.subscribeContentIronRouter = (options, callback) ->
  #  this.subscribe "content", {query: id, details: true}, callback



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

      return self.cursor = self.contentCollection.find(q, opts)

  self.getContentBySourceId = (sourceId) -> self.contentCollection.findOne({sourceId: sourceId})
  self.getContentById = (id) ->
    self.subscribeDetails(id);
    self.contentCollection.findOne(id)

  if (Meteor.isServer)

    Meteor.publish "content", (options = {}) ->
      console.log("client subscribed to content", options)
      if (! options.fields? && ! options.details )
        options.fields = { facebookData: 0, description: 0 }
      self.getContent(options)

    Meteor.methods
      prepareMediaEmbeds: (embedParams) ->

        console.log("preparing embeds")

        # find and update all documents for which we have not generated the media embed for the specified params
        #self.contentCollection.update({},$unset:{embedlyData: ""})

        _.each self.contentCollection.find({embedlyData: { $not: { $elemMatch: embedParams }} }).fetch(), (content) ->
          if (content.link)
            # push empty result so we avoid doing the operation twice
            self.contentCollection.update(content._id, $push:{ embedParams} )
            console.log("running embedly for link:"+content.link)
            params = _.clone(embedParams)
            _.extend(params,embedly.runembedly(_.extend(_.clone(params), {url: content.link}))[0])
            # remove dummy entry and push final
            self.contentCollection.update(content._id, $pull: {embedlyData: embedParams } )
            self.contentCollection.update(content._id, $push: {embedlyData: params})



  #if (Meteor.isClient)
  #  self.contentsubscription = Meteor.subscribe "content"


  return self
