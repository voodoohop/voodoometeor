define "ContentgridController", ["VoodoocontentModel","Config","Embedly"], (model,config,embedly) ->

  console.log("loading content grid")
  self = this

  this.contentTypes = [
    {name: "event", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary"}
    {name: "video", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label"}
    {name: "photo", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning"}
    {name: "link", title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info"}
  ]

  this.sortTypes = [
    {name: "post_date", title:"Post Date", icon:"glyphicon glyphicon-calendar", accessor: (e) -> e.post_date}
    {name: "numlikes", title:"Likes", icon:"glyphicon glyphicon-heart", accessor: (e) -> e.facebookData?.like_count}
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


    postedDate: -> moment(new Date(this.post_date)).fromNow()
    randcol: -> self.colors[_.random(0,self.colors.length-1)]

    contentTypes: -> self.contentTypes

    activeContentFilters: -> Session.get("active_content_filters")

    activeContentFilter: ->_.contains(Session.get("active_content_filters"),this.name)

    isFeatured: () -> (this.isFeatured == true)

    voodoocontent: -> model.getContent()

    numlikes: ->
      this.facebookData?.like_count

    showMedia: -> Session.get(this._id+"_showMedia")

    isSelected: -> Session.get("contentitemSelected") == this._id

    showThumb: -> !Session.get(this._id+"_showMedia")

    embedcontent: ->
      self.getEmbedlyData(this)?.html

    contentTypeMetaData: ->
      _.where(self.contentTypes, {name: this.type })?[0]


    thumbnailurl: ->
      ebdta = self.getEmbedlyData(this)
      thumbnail_url = this.picture ? ebdta?.thumbnail_url
      console.log("thumb:"+thumbnail_url)
      if (thumbnail_url?)
        embedly.getCroppedImageUrl(thumbnail_url, self.embedParams.maxwidth, self.embedParams.maxheight)

  Template.contentgrid.events =
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
      self.isotopeRelayout();
    'click .mediathumb': () ->
      Session.set(this._id+"_showMedia",true)


    'click .sort_filter': () ->
      if (Session.get("active_search_filter") == this.name)
        console.log("reversing sort order")
        Session.set("active_search_filter_reverse",! Session.get("active_search_filter_reverse"))
      else
        Session.set("active_search_filter_reverse",false)

      Session.set("active_search_filter",this.name)

      $("#contentgridcontainer").isotope({sortBy: Session.get("active_search_filter"), sortAscending: Session.get("active_search_filter_reverse") });
      #Meteor.Router.to("/eventdetail/"+this._id)

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
      # check if we can figure out at least one width (incase no elements yet on grid)
      if ($("div.contentitemcontainer").width())
        self.activateIsotopeOnce()
        self.isotopeRelayout()

  self.activateIsotope = _.once( ->
    colWidth = $("div.contentitemcontainer").width()
    console.log("initing isotope with colwidth:"+colWidth)

    sortDataFunctions = {}
    _.each(sortTypes, (e) ->
      sortDataFunctions[e.name] = (j) -> e.accessor(Spark.getDataContext(j.context))
    )

    console.log(sortDataFunctions)
    $("#contentgridcontainer").isotope
      itemSelector: ".masonryitem"
      layoutMode : 'masonry'
      animatonEngine: 'best-available'
      masonry:
        columnWidth: colWidth
      getSortData:
        sortDataFunctions
  )

  self.activateIsotopeOnce = _.debounce(self.activateIsotope, 500)

  self.isotopeRelayout = _.debounce( ->
    $("#contentgridcontainer").isotope('reloadItems').isotope({ sortBy: Session.get("active_search_filter") ? 'original-order' })
    #$("#contentgridcontainer").isotope("reLayout")
  , 500)

  return this
