define "EventMap", ["VoodoocontentModel"], (model) ->
  self = {}

  self.addEventsToMap = (map) ->
    q = {type:"event"}
    model.subscribeContent({query: q})
    window.eventscursor = model.getContent({query: q})
    setTimeout(->
      eventscursor.rewind(); _.each(eventscursor.fetch(), (e) ->
        #icon = new L.icon({iconUrl: "/images/voodoo-48.png", iconSize: [24,24], iconAnchor:[22,16]})

        lat = e.address?.latitude
        long = e.address?.longitude
        if (lat? && long?)
          icon = new L.icon({iconUrl: "http://graph.facebok.com/"+e.sourceId+"/picture",className:"eventmapicon img-circle", iconSize: [40,40], iconAnchor:[20,20]})
          L.marker([lat, long], {icon: icon}).addTo(map).bindPopup("<b><a target='_blank' href='http://fb.com/events/"+e.sourceId+"'>"+e.title+"</a></b><br>"+"<i>"+e.location+"</i>")
      )
    ,10000)
  self.initializeMap = _.once ->
    console.log("loading mapbox external js + css")
    Meteor.Loader.loadJs("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.js", ->
      console.log("loaded mapbox js")
      Meteor.Loader.loadCss("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.css")
      map = L.mapbox.map('eventmapcontainer', 'examples.map-9ijuk24y').setView([-23.55, -46.6333], 13)
      window.map = map
      self.addEventsToMap(map)
    )

  Template.eventmap.rendered = ->
    self.initializeMap()
    return

  return self

require "EventMap", (eventMap) ->
  Router.map ->
    this.route 'eventmap',
      path:'/eventmap'
      template: 'eventmap'
      layoutTemplate: 'mainlayout'

