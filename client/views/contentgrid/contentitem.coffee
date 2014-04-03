define "ContentItem", ["Embedly","VoodoocontentModel","ContentCommon","EventManager","TomMasonry","ContentgridController"], (embedly, model, contentCommon,eventManager, tomMasonry, grid) ->
  self = {}


  self.rsvp_confirmed = (item) ->
    return false unless Meteor.user()
    _.contains(Meteor.user()?.attending, item._id)

  self.helpers =
    typespecificcontent: ->
      res = Template["contentitem_"+this.type]
      return res

    randcol: -> contentCommon.colors[_.random(0,contentCommon.colors.length-1)]

    showMedia: -> grid.isPlayingMedia(this)

    isExpanded: -> grid.isExpanded(this)

    rsvp_confirmed: -> self.rsvp_confirmed(this)
    showDetail: -> grid.isShowDetail(this)

    titleellipsis: ->
      this.title?.substr(0,20) + (if this.title.length >40 then "..." else "")

    showThumb: ->
      ! grid.isPlayingMedia(this)

  console.log("registering content item helpers")
  Template.contentitem.helpers self.helpers

  Template.contentthumb.helpers
    detailPath: ->
      #console.log("detailPath",)
      if (this.contentItem.type=="event")
        "/contentDetail/"+this.contentItem.slug
      else
        "#"
    thumbnailurl: ->

      width = this.overrideWidth ? contentCommon.contentWidthInGrid(this.contentItem)
      height = this.overrideHeight ? contentCommon.contentHeightInGrid(this.contentItem)

      if (this.contentItem.contentTypeMetaData().showtitle and ! this.overrideHeight)
        height -= 50 # footer height should be elsewhere

      thumbnail_url = this.contentItem.getPicture()
      if (!thumbnail_url)
        ebdta = embedly.get(this, width, height)
        thumbnail_url = ebdta?.thumbnail_url
      if (thumbnail_url? and isExternalLink(thumbnail_url))
        embedly.getCroppedImageUrl(thumbnail_url, width, height)
      else
        return thumbnail_url

  Template.contentitem.helpers contentCommon.helpers


  Template.contentitem_event.helpers contentCommon.helpers
  Template.contentitem_event.helpers self.helpers

  model.contentCollection.helpers contentCommon.helpers

  Template.contentitem_video.helpers contentCommon.helpers
  Template.contentitem_video.helpers self.helpers

  Template.contentitem_photo.helpers contentCommon.helpers
  Template.contentitem_link.helpers contentCommon.helpers


  Template.embeddedmedia.helpers
    content: ->
      console.log("embedded media content", embedly.get(this,contentCommon.contentWidthInGrid(this), contentCommon.contentHeightInGrid(this)))
      embedly.get(this,contentCommon.contentWidthInGrid(this), contentCommon.contentHeightInGrid(this))?.html




  Template.contentitem.events

    'click .mediaplaybutton': () ->
      console.log(this)
      console.log("showmedia: "+this._id)
      grid.playMedia(this)



  Meteor.startup ->
    $(window).scroll _.debounce( ->
      if (grid.selectedItem().showingDetail and self.listenForDetailLeavingWindow)
        detailtop = $("#"+grid.selectedItem().id).offset().top
        if Math.abs($(window).scrollTop() - detailtop) > $(window).height()/2
          gridwidth = contentCommon.contentWidthInGrid(Rselected.openDetailItem)
          gridheight = contentCommon.contentHeightInGrid(Rselected.openDetailItem)
          console.log("animating closing:",gridwidth, gridheight)
          $("#"+grid.selectedItem().id).animate(
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

  return self;