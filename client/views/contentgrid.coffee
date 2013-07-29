Template.eventgrid.events = null

define "ContentgridController", ["VoodoocontentModel","Config"], (model,config) ->
  self = this
  Template.contentgrid.helpers
    isFeatured: () -> (this.isFeatured == true)
    voodoocontent: model.getContent
    prepareembed: ->
      if (this.link)
        console.log "calling remote embedly for:"+this.link
        innerself = this
        this.embedcontent = "";
        embedlykey = config.current().embedly.key
        result = Meteor.call("embedly",{url: this.link, maxwidth: 250, maxheight:250, autoplay: true}, (err, res) ->
          console.log(res)
          innerself.embedcontent_tmp =  res[0].html
          $("#mediathumb_"+innerself._id).html("<img src='http://i.embed.ly/1/display/crop?height="+res[0].height+"&width="+res[0].width+"&url="+encodeURI(res[0].thumbnail_url)+"&key="+embedlykey+"'>")
          #console.log(innerself)
        )
        #console.log("stub response:"+result)
        #console.log("stub response:"+res)
        return "hello"

  Template.contentgrid.events =
    'click .contentitemcontainer':  ->
#      $("#"+this._id).css("height","500px")
#      $("#"+this._id).css("width","500px")
#      self.isotopeRelayout()
      console.log(this)
      $("#mediathumb_"+this._id).hide()
      $("#mediacontent_"+this._id).html(this.embedcontent_tmp);
      #this.embedcontent=this.embedcontent_tmp
      #Meteor.Router.to("/eventdetail/"+this._id)

  Template.contentgrid.rendered = ->
    console.log("rendered")
    Meteor.defer ->
      self.isotopeRelayout()
#    $("#eventgridcontainer").addClass("js-masonry")
#    $("#eventgridcontainer").masonry()

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
