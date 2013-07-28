Template.eventgrid.events = null

define "EventgridController", ["VoodooeventModel"], (model) ->
  self = this
  Template.eventgrid.helpers
    isLargeImage: () -> (parseInt(this.isvoodoo) == 1)
    voodooevents: model.getAllEventsForList

  Template.eventgrid.events =
    'click .voodooeventcontainer':  ->
#      $("#"+this._id).css("height","500px")
#      $("#"+this._id).css("width","500px")
#      self.isotopeRelayout()
      Meteor.Router.to("/eventdetail/"+this._id)
  Template.eventgrid.created = ->

  Template.eventgrid.rendered = ->
    console.log("rendered")
    Meteor.defer ->
      self.isotopeRelayout()
#    $("#eventgridcontainer").addClass("js-masonry")
#    $("#eventgridcontainer").masonry()

  self.activateIsotopeOnce = _.once ->
      console.log("activating isotope masonry")
      $("#eventgridcontainer").isotope
        itemSelector: ".masonryitem"
        layoutMode : 'masonry'
        animatonEngine: 'best-available'
  self.isotopeRelayout = _.debounce( ->
    self.activateIsotopeOnce()
    console.log("layouting isotope")
    $("#eventgridcontainer").isotope("reLayout")
  , 300)

  return this
