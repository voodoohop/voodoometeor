define "ContentItem", ["Embedly"], (embedly) ->
  self = {}

  initState = (item) ->
    item.state = new ReactiveObject {isPlaying: false}


  self.rsvp_confirmed = (item) ->
    return false unless Meteor.user()
    _.contains(Meteor.user()?.attending, item._id)

  self.helpers =
    typespecificcontent: ->
      Template["contentitem_"+this.type]

    showMedia: ->
      initState(this) unless this.state?
      this.state.isPlaying

    rsvp_confirmed: -> self.rsvp_confirmed(this)

    titleellipsis: ->
      this.title?.substr(0,20) + (if this.title.length >40 then "..." else "")

    showThumb: ->! this.state.isPlaying

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
      console.log("this.contentItem", this.contentItem)
      width = this.overrideWidth ?  this.contentItem.widthInGrid()
      height = this.overrideHeight ? this.contentItem.heightInGrid()
      if (this.contentItem.metaData().showtitle and ! this.overrideHeight)
        height -= 50 # footer height should be elsewhere

      thumbnail_url = this.contentItem.getPicture()
      if (!thumbnail_url)
        console.log("no thumb_url found, calling embedly for thumbnail:",width, height)
        ebdta = embedly.getEmbedlyData({url: this.contentItem.link,maxwidth:width, maxheight: height})
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
      res = embedly.getEmbedlyData({url: this.link,maxwidth:widthInGrid, maxheight:heightInGrid, autoplay: true})?.html
      console.log(res)
      res

  Template.contentitem.created = -> initState(this.data)
  Template.contentitem.events

    'click .mediaplaybutton': (event,tmplInstance) ->
      console.log("content item state",tmplInstance.data.state)
      tmplInstance.data.state.isPlaying = true
      #grid.playMedia(this)





  return self;