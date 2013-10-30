define "ContentItem", ["Embedly","VoodoocontentModel","ContentCommon","EventManager"], (embedly, model, contentCommon,eventManager) ->
  self = {}

  self.embedParams = {maxwidth: 260, maxheight: 280, autoplay: true}

  self.colors= [
    "#428bca"
    "#5cb85c"
    "#f0ad4e"
    "#d9534f"
    "#5bc0de"
  ]

  Meteor.call("prepareMediaEmbeds", self.embedParams)

  self.getEmbedlyData = (data) -> _.findWhere(data.embedlyData, self.embedParams)

  self.helpers =
    typespecificcontent: ->
      #console.log "specific",new Handlebars.SafeString(Template["contentitem_"+this.type]())
      return new Handlebars.SafeString(Template["contentitem_"+this.type](this))

    randcol: -> self.colors[_.random(0,self.colors.length-1)]

    showMedia: -> Session.get(this._id+"_showMedia")

    isExpanded: -> Session.get("contentitemSelected") == this._id

    description: ->
      model.getDetails(this._id)
      this.description

    description_reduced: ->
      console.log("reducing", this)
      this.description.substring(0,300)+ "..."
    rsvp_confirmed: ->
      _.contains(Meteor.user()?.attending, this._id)


  Template.contentitem.helpers self.helpers



  Template.contentthumb.helpers

    showThumb: -> !Session.get(this._id+"_showMedia")

    thumbnailurl: ->
      ebdta = self.getEmbedlyData(this)
      thumbnail_url = this.picture ? ebdta?.thumbnail_url
      # console.log("thumb:"+thumbnail_url)
      if (thumbnail_url?)
        embedly.getCroppedImageUrl(thumbnail_url, self.embedParams.maxwidth, self.embedParams.maxheight)


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
    content: -> self.getEmbedlyData(this)?.html


  Template.contentitem.events =
    'click .rsvpbutton': () ->
      eventManager.rsvp(this._id, true)

    'click .mediathumb': () ->
      console.log(this)
      #$(".contentitemcontainer").not("#"+this._id).removeClass("wide").removeClass("front").removeClass("tall")
      if (Session.get("contentitemSelected",this._id))
        Session.set("contentitemSelected",null)
      else
        Session.set("contentitemSelected",this._id)
      #$("#"+this._id).toggleClass("wide")
      #$("#"+this._id).toggleClass("front")
      #$("#"+this._id).toggleClass("tall")
      #packery.inst.fit($("#"+this._id)[0]) if packery.inst?
    'click .mediaplaybutton': () ->
      console.log("showmedia: "+this._id)
      Session.set(this._id+"_showMedia",true)

  return self;