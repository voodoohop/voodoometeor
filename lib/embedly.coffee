define "Embedly", ["Config","VoodoocontentModel"],  (config, model) ->
  self = {}

  self.getCroppedImageUrl = (srcimg, width, height) ->
    "http://i.embed.ly/1/display/crop?height="+height+"&width="+width+"&url="+encodeURI(srcimg)+"&key="+self.embedly_key()

  self.embedly_key = -> config.current().embedly.key

  self.embedParams = {autoplay: true}

  if (Meteor.isClient)
    self.get = (data, maxwidth, maxheight) ->
      params = _.defaults(self.embedParams, {maxwidth: maxwidth, maxheight: maxheight})
      res = _.findWhere(data.embedlyData, params)
      #console.log("got embed data",params, res)
      unless res
        console.log("not found embedly data for embedparams, loading", data, params)
        Meteor.call("prepareMediaEmbeds",
          id: data._id
          params: params
        )
      return res

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
      console.log("running embedly", params)
      return Meteor.sync( (done) ->
        embedlyapi.oembed _.clone(params), (err, result) ->
          console.log(result)
          done(null, result)
      ).result

    #console.log("removing embedly data")
    #model.contentCollection.update({},$unset:{embedlyData: ""},{multi: true})
    #model.contentCollection.update({},$unset:{embedParams: ""},{multi: true})

    self.prepareMediaEmbeds = (content, options, isdefault=false) ->
        console.log("preparing embeds",options)
        if (content?.link)
            ## push empty result so we avoid doing the operation twice
            #model.contentCollection.update(content._id, $push:{ embedlyData: embedParams} )
            console.log("running embedly for link:"+content.link, "default", isdefault)
            params = _.clone(options.params)
            _.extend(params,self.runembedly(_.defaults(params, {url: content.link}))[0])
            params.default = true
            # remove dummy entry and push final
            #model.contentCollection.update(content._id, $pull: {embedlyData: embedParams } )
            model.contentCollection.update(content._id, $push: {embedlyData: params})

    Meteor.methods
      prepareMediaEmbeds: (options) ->
        content = model.contentCollection.findOne({_id: options.id, embedlyData: { $not: { $elemMatch: options.params }} })
        this.unblock()
        self.prepareMediaEmbeds(content, options)

    Meteor.defer ->
      return
      console.log("loading default embedly data")

      query =
        type: {$ne: "event"}
        $or: [{embedlyData: {$exists: false}}, {embedlyData: {$size: 0}}]

      _.each(model.contentCollection.find(query).fetch(), (item) ->
        console.log("previous embedly data:",item.embedlyData)
        self.prepareMediaEmbeds(item, {params:{autoPlay: true}}, true)
      )
      console.log("done loading default embedly data")
  return self
