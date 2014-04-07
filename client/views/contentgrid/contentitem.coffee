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
        if (this.contentItem.type=="link")
          this.contentItem.link

    thumbnailurl: ->
      console.log(this.contentItem)
      width = this.overrideWidth ? this.contentItem.widthInGrid()
      height = this.overrideHeight ? this.contentItem.heightInGrid()
      if (this.contentItem.metaData().showtitle and ! this.overrideHeight)
        height -= 50 # footer height should be elsewhere

      thumbnail_url = this.contentItem.getPicture()
      if (!thumbnail_url)
        console.log("no thumb_url found, calling embedly for thumbnail:",width, height)
        ebdta = embedly.get(this.contentItem, width, height)
        thumbnail_url = ebdta?.thumbnail_url
      if (thumbnail_url? and isExternalLink(thumbnail_url))
        embedly.getCroppedImageUrl(thumbnail_url, width, height)
      else
        return thumbnail_url

  Template.contentitem_event.helpers self.helpers

  Template.contentitem_video.helpers self.helpers

  Template.embeddedmedia.helpers
    content: ->
      widthInGrid = this.widthInGrid()
      heightInGrid = this.heightInGrid()

      console.log("calling embedly width width, height", widthInGrid, heightInGrid)
      res = embedly.getEmbedlyData({url: this.link,maxwidth:widthInGrid, maxheight:heightInGrid})?.html
      console.log(res)
      res


  Template.contentitem.events

    'click .mediaplaybutton': () ->
      console.log(this)
      console.log("showmedia: "+this._id)
      grid.playMedia(this)





  return self;