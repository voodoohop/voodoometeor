define "ContentgridController", ["VoodoocontentModel","Config","Embedly","PackeryMeteor","ContentCommon"], (model,config,embedly,packery,contentCommon) ->

  console.log("loading content grid")
  self = {}

  self.subscribeFilteredSortedContent = (callback)  ->
    content_sort = Session.get("content_sort")
    if content_sort?
      sort = {}
      sort[content_sort.name] = content_sort.order
    filters =  {}
    _.each Session.get("active_content_filters"), (f) ->
      filters["type"] = f
    options =
      query: filters
      sort: sort
    model.subscribeContent(options, -> Session.set("contentoptions", options); callback() if callback? )#, -> Session.set("voodoocontent", model.getContent()))

  self.contentTypes = contentCommon.contentTypes;

  self.sortTypes = [
    {name: "post_date", title:"Post Date", icon:"glyphicon glyphicon-calendar", accessor: (e) -> e?.post_date}
    {name: "facebookData.like_count", title:"Likes", icon:"glyphicon glyphicon-heart", accessor: (e) -> e?.facebookData?.like_count}
  ]

  self.colors= [
    "#428bca"
    "#5cb85c"
    "#f0ad4e"
    "#d9534f"
    "#5bc0de"
  ]

  Meteor.startup ->

  Session.set("active_content_filters",[])
  Session.set("content_sort", {name: "post_date", order: 1})



  Deps.autorun ->
    console.log("subscribing to content")
    self.subscribeFilteredSortedContent((content) ->
      self.voodoocontent=model.getContent(Session.get("contentoptions"))

      console.log(self.voodoocontent)
      console.log("received content")
      self.voodoocontent.observe
        addedAt: (doc, index) ->
         #console.log("addedAt",doc,index)

        removedAt: (doc, index) ->
          console.log("removedAt",doc,index)

        changedAt: (doc, olddoc, index) ->
          console.log("removedAt",doc,olddoc, index)

        movedTo: (doc, fromindex, toindex) ->
          console.log("movedTo", doc, fromindex, toindex)

    )


  self.embedParams = {maxwidth: 250, maxheight:200, autoplay: true}

  Meteor.call("prepareMediaEmbeds", self.embedParams)

  self.getEmbedlyData = (data) -> _.findWhere(data.embedlyData, self.embedParams)


  Template.contentitem.helpers

    numlikestosize: ->
      Math.max(200,Math.min(400,this.facebookData?.like_count*10))

    randcol: -> self.colors[_.random(0,self.colors.length-1)]

    showMedia: -> Session.get(this._id+"_showMedia")

    isSelected: -> Session.get("contentitemSelected") == this._id

    showThumb: -> !Session.get(this._id+"_showMedia")

    thumbnailurl: ->
      ebdta = self.getEmbedlyData(this)
      thumbnail_url = this.picture ? ebdta?.thumbnail_url
      # console.log("thumb:"+thumbnail_url)
      if (thumbnail_url?)
        embedly.getCroppedImageUrl(thumbnail_url, self.embedParams.maxwidth, self.embedParams.maxheight)

  Template.contentitem.helpers contentCommon.helpers

  Template.contentitem.helpers model.helpers

  Template.embeddedmedia.helpers
    content: -> self.getEmbedlyData(this)?.html

  Template.navbar.helpers
    contentTypes: -> self.contentTypes
    sortTypes: -> self.sortTypes
    activeContentFilters: -> Session.get("active_content_filters")

    activeContentFilter: -> if _.contains(Session.get("active_content_filters"),this.name) then "active" else ""


  Template.contentgrid.voodoocontent = -> model.getContent(Session.get("contentoptions"))

  Template.contentgrid.events =
    'click': -> console.log("click")

  Template.contentitem.events =
    'click .mediatitle': () ->
      console.log(this)
      $(".contentitemcontainer").not("#"+this._id).removeClass("wide").removeClass("front").removeClass("tall")
      if (Session.get("contentitemSelected",this._id))
        Session.set("contentitemSelected",null)
      else
        Session.set("contentitemSelected",+this._id)
      $("#"+this._id).toggleClass("wide")
      $("#"+this._id).toggleClass("front")
      $("#"+this._id).toggleClass("tall")
      packery.inst.fit($("#"+this._id)[0]) if packery.inst?
    'click .mediathumb': () ->
      console.log("showmedia: "+this._id)
      Session.set(this._id+"_showMedia",true)

  Template.navbar.events =
    'click .sort_filter': () ->
      content_sort = Session.get("content_sort")
      Session.set("content_sort",
        name: this.name
        order: (if content_sort.name == this.name then content_sort.order * -1 else 1)
      )
      console.log(Session.get("content_sort"))

      #Meteor.Router.to("/eventdetail/"+this._id)

    'click .content_filter': () ->
      filters = Session.get("active_content_filters") ? []
      if (_.contains(filters,this.name))
        filters = _.without filters, this.name
      else
        filters.push(this.name)
      Session.set("active_content_filters",filters)
      console.log(filters)



  Template.contentgrid.rendered = ->
    console.log("rendered")

  Template.contentitem.rendered = ->
    console.log("item rendered")

  return self
