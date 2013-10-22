define "VoodoocontentModel",["Embedly"], (embedly) ->

  self= {};

  self.contentBlockSize = 10

  self.helpers =
    postedDate: -> moment(new Date(this.post_date)).fromNow()
    isFeatured: -> (this.isFeatured == true)
    numlikes: -> this.facebookData?.like_count ? 0

  # content for rendering grid
  self.contentCollection =  new Meteor.Collection("voodoocontent")

  self.subscribeContent = (options, callback) ->
    Meteor.subscribe "content", options, callback

  self.getContent = (options) ->
      console.log options
      self.contentCollection.find( options?.query ? {},
      #  skip: self.contentBlockSize *  (options.blockno ? 0)
      #  limit: self.contentBlockSize
        fields: options?.fields? null
        sort: options?.sort
      )

  self.getContentBySourceId = (sourceId) -> self.contentCollection.find({sourceId: sourceId})

  if (Meteor.isServer)

    Meteor.publish "content", (query={}, blockno=0, fields={}) ->
      console.log("client subscribed to content at blockno:"+blockno)
      console.log(query)


      self.getContent(query,blockno,fields)

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
