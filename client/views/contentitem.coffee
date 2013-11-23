define "ContentItem", ["Embedly","VoodoocontentModel","ContentCommon","EventManager","TomMasonry"], (embedly, model, contentCommon,eventManager, tomMasonry) ->
  self = {}


  self.rsvp_confirmed = (item) ->
    return false unless Meteor.user()
    _.contains(Meteor.user()?.attending, item._id)


  self.helpers =
    typespecificcontent: ->
      res = Template["contentitem_"+this.type](this)
      return res

    randcol: -> contentCommon.colors[_.random(0,contentCommon.colors.length-1)]

    showMedia: -> Session.get(this._id+"_showMedia")

    isExpanded: -> (Session.get("contentitemSelected") == this._id) or this.expanded

    rsvp_confirmed: -> self.rsvp_confirmed(this)
    showDetail: -> Session.get("showDetail") == this._id

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
      if (thumbnail_url?)
        #console.log "metadata",contentCommon.getContenttypeMetadata(this)
        height = contentCommon.contentHeightInGrid(this)
        width = contentCommon.contentWidthInGrid(this)
        embedly.getCroppedImageUrl(thumbnail_url, width, height)


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
      Session.set("showDetail", this._id)
      #detailSubscription = model.subscribeDetails(this._id);
      this.justExpanded = true;
      console.log(this)
      if (Session.get("contentitemSelected") == this._id)
        Session.set("contentitemSelected",null)
      else
        Session.set("contentitemSelected",this._id)

    'click .mediaplaybutton': () ->
      console.log(this)
      console.log("showmedia: "+this._id)
      Session.set("contentitemSelected",this._id)
      Session.set(this._id+"_showMedia",true)

  Template.contentitem.rendered = ->
    data = this.data
    if (data.justExpanded)
      data.justExpanded = undefined
      Meteor.defer ->
        tomMasonry.ms.on( 'layoutComplete',handler = ->
          tomMasonry.ms.off('layoutComplete', handler)
          $(window).scrollTo("#"+data._id,500)
        )
        tomMasonry.ms.layout()

  Deps.autorun ->
    console.log("subscribing to detail", Session.get("showDetail"))
    model.subscribeDetails(Session.get("showDetail"))

  return self;