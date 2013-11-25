define "ContentItem", ["Embedly","VoodoocontentModel","ContentCommon","EventManager","TomMasonry","ContentgridController"], (embedly, model, contentCommon,eventManager, tomMasonry, grid) ->
  self = {}


  self.rsvp_confirmed = (item) ->
    return false unless Meteor.user()
    _.contains(Meteor.user()?.attending, item._id)


  Rselected = grid.RselectedItem

  self.helpers =
    typespecificcontent: ->
      res = Template["contentitem_"+this.type](this)
      return res

    randcol: -> contentCommon.colors[_.random(0,contentCommon.colors.length-1)]

    showMedia: -> Rselected.id == this._id  and Rselected.playingMedia

    isExpanded: -> (Rselected.id == this._id) or this.expanded

    rsvp_confirmed: -> self.rsvp_confirmed(this)
    showDetail: -> Rselected.id == this._id and Rselected.showingDetail

    titleellipsis: ->
      this.title?.substr(0,40) + (if this.title.length >40 then "..." else "")

  Template.contentitem.helpers self.helpers

  Template.contentthumb.helpers

    showThumb: -> !Session.get(this._id+"_showMedia")

    thumbnailurl: ->

      thumbnail_url = this.picture
      if (!thumbnail_url)
        ebdta = embedly.get(this, contentCommon.contentWidthInGrid(this), contentCommon.contentHeightInGrid(this))
        thumbnail_url = ebdta?.thumbnail_url
      # console.log("thumb:"+thumbnail_url)
      if (thumbnail_url? and isExternalLink(thumbnail_url))
        #console.log "metadata",contentCommon.getContenttypeMetadata(this)
        height = contentCommon.contentHeightInGrid(this)
        width = contentCommon.contentWidthInGrid(this)
        embedly.getCroppedImageUrl(thumbnail_url, width, height)
      else
        return thumbnail_url

  Template.contentitem.helpers contentCommon.helpers

  Template.contentitem.helpers model.helpers

  Template.contentitem_event.helpers model.helpers
  Template.contentitem_event.helpers contentCommon.helpers
  Template.contentitem_event.helpers self.helpers



  Template.contentitem_video.helpers model.helpers
  Template.contentitem_video.helpers contentCommon.helpers
  Template.contentitem_photo.helpers model.helpers
  Template.contentitem_photo.helpers contentCommon.helpers
  Template.contentitem_link.helpers model.helpers
  Template.contentitem_link.helpers contentCommon.helpers


  Template.embeddedmedia.helpers
    content: -> embedly.get(this,contentCommon.contentWidthInGrid(this), contentCommon.contentHeightInGrid(this))?.html




  Template.contentitem.events =
    'click .rsvp_decline': () ->
      eventManager.rsvp(this._id, false)
    'click .rsvp_attend': () ->
      eventManager.rsvp(this._id, true)

    'click .mediathumb': () ->
      #detailSubscription = model.subscribeDetails(this._id);
      this.justExpanded = true;
      console.log(this)
      if (Rselected.id == this._id)
        Rselected.id = null
        Rselected.showMedia = false
        Rselected.showingDetail = false
      else
        Rselected.id = this._id
        Rselected.showMedia = false
        Rselected.showingDetail = true

    'click .mediaplaybutton': () ->
      console.log(this)
      console.log("showmedia: "+this._id)
      Rselected.id = this._id
      Rselected.showMedia = true

  Template.contentitem.rendered = ->
    data = this.data
    if (data.justExpanded)
      data.justExpanded = undefined
      Meteor.defer ->
        tomMasonry.ms.on( 'layoutComplete',handler = ->
          tomMasonry.ms.off('layoutComplete', handler)
          $(window).scrollTo("#"+data._id,500,
            onAfter: -> self.listenForDetailLeavingWindow = true
          )
        )
        tomMasonry.ms.layout()

  Meteor.startup ->
    $(window).scroll _.debounce( ->
      if (Rselected.showingDetail and self.listenForDetailLeavingWindow)
        detailtop = $("#"+Rselected.id).offset().top
        if Math.abs($(window).scrollTop() - detailtop) > $(window).height()/2
          gridwidth = contentCommon.contentWidthInGrid(self.openDetailItem)
          gridheight = contentCommon.contentHeightInGrid(self.openDetailItem)
          console.log("animating closing:",gridwidth, gridheight)
          $("#"+Rselected.id).animate(
            width: ""+gridwidth+"px"
            height: ""+gridheight+"px"
          , 200, null, ->
            self.listenForDetailLeavingWindow = false
            Rselected.showingDetail = false
            Rselected.id = null)
          Meteor.setTimeout( ->
            tomMasonry.debouncedRelayout()
          , 500)
    , 500)


  Deps.autorun ->
    if (Rselected.showingDetail)
      console.log("subscribing to detail", Rselected.id)
      model.subscribeDetails(Rselected.id, ->
        self.openDetailItem = model.getContentById(Rselected.id)
        console.log("open detail item:", self.openDetailItem)
      )
    else
      model.subscribeDetails(null)
  return self;