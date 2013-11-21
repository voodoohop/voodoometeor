define "TomDivIcon", [], ->
  #
  # * L.DivIcon is a lightweight HTML-based icon class (as opposed to the image-based L.Icon)
  # * to use with L.Marker.
  #
  @L.TomDivIcon = L.Icon.extend(
    options:
      iconSize: [12, 12]
      className: "leaflet-div-icon"
      html: false

    createIcon: (oldIcon) ->
      if (oldIcon)
        alert("new icon from old")
      options = @options
      if options.div isnt false
        div = options.div
        div.style.backgroundPosition = (-options.bgPos.x) + "px " + (-options.bgPos.y) + "px"  if options.bgPos
        @_setIconStyles div, "icon"
        div
      else
        null

    createShadow: ->
      null
  )
  @L.tomDivIcon = (options) ->
    new L.TomDivIcon(options)

define "LeafletUtils", [], ->
  self = {}
  self.initializeMap = _.once (options) ->
    console.log("loading mapbox external js + css")
    Meteor.Loader.loadJs("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.js", ->
     Meteor.Loader.loadJs("/js/leaflet.markercluster.js", ->
      require "TomDivIcon", (tomDivIcon) ->
        self.tomDivIcon = tomDivIcon;
      console.log("loaded mapbox js")
      Meteor.Loader.loadCss("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.css")
      self.map = L.mapbox.map('eventmapcontainer', 'examples.map-9ijuk24y').setView([-23.55, -46.6333], 13)  #examples.a4c252ab
      options.mapCreated(self.map);
     )
    )


  self.markermanager = (options) ->
    me = {}
    markers = {}

    clusterer = new L.MarkerClusterGroup(
      #removeOutsideVisibleBounds: false
      animateAddingMarkers: true
      maxClusterRadius: 20
      spiderfyOnMaxZoom: true
      iconCreateFunction: (cluster) ->
        icondiv = options.clusterIconCreate(cluster);
        self.tomDivIcon({div: icondiv, className: "eventmapclustertooltip", iconSize: L.point(40,60), iconAnchor: [20,60]})
      )
    self.map.addLayer(clusterer)
    me.observer =
      added: (e) ->
        #console.log("added",e)
        Session.set("markerscount",Session.get("markerscount")+1)
        id = e._id
        latlng = options.getLatLng(e)
        lat = latlng?.latitude
        long = latlng?.longitude
        if (lat? and long?)
          lat += Math.random() * 0.00005
          long += Math.random() * 0.00005
          iconhtml = Meteor.render( -> options.markerTemplate(e))
          icondivchild = L.DomUtil.create("div","lbqs")
          icondivchild.appendChild(iconhtml)
          icon = self.tomDivIcon(
            className: "blabla"
            iconSize: [40,60]
            iconAnchor: [20,60]
            div: icondivchild
          )
          e.expanded = true
          #html = Template.contentitem(e)
          m = L.marker([lat, long]  , {icon: icon}).on(
            "click": (info) ->
              #console.log("info", m._popup)
              if m._popup?
                return
              div = L.DomUtil.create("div","lbqs")
              options.popupCreate(e, div, ->
                m.bindPopup(div).openPopup()
              )
          #popup = L.popup().setLatLng(info.latlng).setContent(content).openOn(map)
            "popupclose": (e) ->
              options.popupClose(e)
          )
          m.data = e


          #console.log(m)
          #console.log("clustererlatproblem",clusterer,m)
          me.batchifiedMarkerAdd(m)
          #clusterer.addLayer(m)
          markers[e._id] = m
      removed: (e) ->
        Session.set("markerscount",Session.get("markerscount")-1)
        #console.log("deleting marker",markers[e._id])
        lat = e.address?.latitude
        long = e.address?.longitude
        unless (lat? and long?)
          return
        #console.log("removed",e._id)
        if markers[e._id]
          clusterer.removeLayer(markers[e._id])
        else
          console.log("no marker",markers, e._id)
        delete markers[e._id]
      changed: (e) ->
        console.log("changed",e._id)
          #markers[e._id].setPopupContent(Meteor.render( -> Template.contentitem(e)))   #unless markers[e._id]._popup?
          #  return
          #console.log("changed", e)
          #console.log(markers[e._id])
          #console.log("changed",Meteor.render( -> Template.contentitem(e)))
    me.individualMarkerAdd = (marker) ->
      clusterer.addLayer(marker);
      if (options.addedMarkers?)
        options.addedMarkers();
    me.batchifiedMarkerAdd = batchify( me.individualMarkerAdd , (markers) ->
      console.log("batch adding "+markers.length+" markers")
      clusterer.addLayers(_.flatten(markers))
      if (options.addedMarkers?)
        options.addedMarkers();
    , 500)
    return me;
  return self;