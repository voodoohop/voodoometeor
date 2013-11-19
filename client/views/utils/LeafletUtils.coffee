define "TomDivIcon", [], ->
  #
  # * L.DivIcon is a lightweight HTML-based icon class (as opposed to the image-based L.Icon)
  # * to use with L.Marker.
  #
  @L.TomDivIcon = L.Icon.extend(
    options:
      iconSize: [12, 12] # also can be set through CSS
      #
      #                iconAnchor: (Point)
      #                popupAnchor: (Point)
      #                html: (String)
      #                bgPos: (Point)
      #
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
  self.markermanager = (markerAdder, markerLayer, popupCreator) ->
    self.markers = {}
    observer =
      added: (e) ->
       Session.set("markerscount",Session.get("markerscount")+1)
       require "TomDivIcon",(tomDivIcon) ->
        id = e._id
        lat = e.address?.latitude
        long = e.address?.longitude
        if (lat? and long?)
          lat += Math.random() * 0.00005
          long += Math.random() * 0.00005
          iconhtml = Meteor.render( -> Template.eventmapmarker(e))
          icondivchild = L.DomUtil.create("div","lbqs")
          icondivchild.appendChild(iconhtml)
          icon = tomDivIcon(
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
              popupCreator.popupCreate(e, div, ->
                m.bindPopup(div).openPopup()
              )
          #popup = L.popup().setLatLng(info.latlng).setContent(content).openOn(map)
            "popupclose": (e) ->
              popupCreator.popupClose(e)
          )
          m.data = e


          #console.log(m)
          #console.log("clustererlatproblem",self.clusterer,m)
          markerAdder(m)
          #self.clusterer.addLayer(m)
          self.markers[e._id] = m
      removed: (e) ->
        Session.set("markerscount",Session.get("markerscount")-1)
        #console.log("deleting marker",self.markers[e._id])
        lat = e.address?.latitude
        long = e.address?.longitude
        unless (lat? and long?)
          return
        #console.log("removed",e._id)
        if self.markers[e._id]
          markerLayer.removeLayer(self.markers[e._id])
        else
          console.log("no marker",self.markers, e._id)
        delete self.markers[e._id]
      changed: (e) ->
        console.log("changed",e._id)
        #self.markers[e._id].setPopupContent(Meteor.render( -> Template.contentitem(e)))   #unless self.markers[e._id]._popup?
        #  return
        #console.log("changed", e)
        #console.log(self.markers[e._id])
        #console.log("changed",Meteor.render( -> Template.contentitem(e)))
  return self;