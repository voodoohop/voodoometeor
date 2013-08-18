define "ContentgridController", ["VoodoocontentModel","Config","Embedly"], (model,config,embedly) ->

  console.log("loading content grid")
  self = this

  this.contentTypes = [
    {name: "event", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary"}
    {name: "video", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label"}
    {name: "photo", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning"}
    {name: "link", title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info"}
  ]

  this.colors= [
    "#428bca"
    "#5cb85c"
    "#f0ad4e"
    "#d9534f"
    "#5bc0de"
  ]

  Template.contentgrid

  Session.set("active_content_filters",[])

  this.embedParams = {maxwidth: 250, maxheight:200, autoplay: true}

  Meteor.call("prepareMediaEmbeds", this.embedParams)

  this.getEmbedlyData = (data) -> _.findWhere(data.embedlyData, self.embedParams)

  Template.contentgrid.helpers

    randcol: -> self.colors[_.random(0,self.colors.length-1)]

    contentTypes: -> self.contentTypes

    activeContentFilters: -> Session.get("active_content_filters")

    activeContentFilter: ->_.contains(Session.get("active_content_filters"),this.name)

    isFeatured: () -> (this.isFeatured == true)

    voodoocontent: -> model.getContent()

    numlikes: ->
      this.facebookData?.like_count

    showMedia: -> Session.get(this._id+"_showMedia")

    showThumb: -> !Session.get(this._id+"_showMedia")

    embedcontent: ->
      self.getEmbedlyData(this)?.html

    contentTypeMetaData: ->
      _.where(self.contentTypes, {name: this.type })?[0]


    thumbnailurl: ->
      ebdta = self.getEmbedlyData(this)
      thumbnail_url = this.picture ? ebdta?.thumbnail_url
      console.log(thumbnail_url)
      if (thumbnail_url?)
        embedly.getCroppedImageUrl(thumbnail_url, self.embedParams.maxwidth, self.embedParams.maxheight)

  Template.contentgrid.events =
    'click .contentitemcontainer': () ->
      Session.set(this._id+"_showMedia",true)
      console.log(this)
    'click .content_filter': () ->
      filters = Session.get("active_content_filters") ? []
      if (_.contains(filters,this.name))
        filters = _.without filters, this.name
      else
        filters.push(this.name)

      $("#contentgridcontainer").isotope({filter: _.map(filters, (f) -> ".content_type_"+f ).join(",") });
      Session.set("active_content_filters",filters)
      console.log(filters)
      #Meteor.Router.to("/eventdetail/"+this._id)

  Template.contentgrid.rendered = ->
    console.log("rendered")
    Meteor.defer ->
      self.isotopeRelayout()


  self.activateIsotopeOnce = _.once ->
    console.log("activating isotope masonry")
    $("#contentgridcontainer").isotope
      itemSelector: ".masonryitem"
      layoutMode : 'masonry'
      animatonEngine: 'best-available'

  self.isotopeRelayout = _.debounce( ->
    self.activateIsotopeOnce()
    #$("#contentgridcontainer").isotope("reLayout")
  , 500)

  return this
