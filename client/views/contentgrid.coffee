Template.eventgrid.events = null

define "ContentgridController", ["VoodoocontentModel","Config","Embedly"], (model,config,embedly) ->
  self = this

  console.log("current config")
  console.log(config.current())
  this.embedParams = {maxwidth: 350, maxheight:300, autoplay: true}

  Meteor.call("prepareMediaEmbeds", this.embedParams)

  this.getEmbedlyData = (data) -> _.findWhere(data.embedlyData, self.embedParams)

  Template.contentgrid.helpers

    isFeatured: () -> (this.isFeatured == true)

    voodoocontent: -> model.getContent()

    numlikes: ->
      this.facebookData?.like_count

    showMedia: -> Session.get(this._id+"_showMedia")

    showThumb: -> !Session.get(this._id+"_showMedia")

    embedcontent: ->
      ebdta = self.getEmbedlyData(this)
      if ebdta?
        if ebdta.html?
           return ebdta.html

    thumbnailurl: ->
      ebdta = self.getEmbedlyData(this)
      thumbnail_url = this.picture ? ebdta?.thumbnail_url
      console.log(thumbnail_url)
      if (thumbnail_url?)
        embedly.getCroppedImageUrl(thumbnail_url, self.embedParams.maxwidth, self.embedParams.maxheight)

  Template.contentgrid.events =
    'click .contentitemcontainer': () ->
#      $("#"+this._id).css("height","500px")
#      $("#"+this._id).css("width","500px")
      Session.set(this._id+"_showMedia",true)
      console.log(this)
 #     self.isotopeRelayout()

      #this.embedcontent=this.embedcontent_tmp
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
    console.log("layouting isotope")
    $("#contentgridcontainer").isotope("reLayout")
  , 300)

  return this
