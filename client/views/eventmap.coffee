define "EventMap", ["VoodoocontentModel", "ContentItem"], (model, contentItem) ->
  self = {}
  self.markers = {}
  Template.contentitem_event.helpers model.helpers
  Template.eventmapmarker.helpers contentItem.helpers
  Template.eventmap.events
    'keypress input.maptextfilter': ->

  Template.eventmapmarker.rendered = ->
    Meteor.setTimeout( ->
      $(".eventmapmarkertooltip").tooltip()
    , 500)

  self.addEventsToMap = (map) ->
    q =
      type:"event"
      #title: { $regex: "oodoo", $options:"i" }
        #  post_date:
        #"$gte": moment().subtract("hours",8).toISOString()
        #"$lte": moment().add("days",1).toISOString()

    model.subscribeContent({query: q})
    eventscursor = model.getContent({query: q})

    eventscursor.observe
      added: (e) ->
        #console.log("added to map",e)
        #icon = new L.icon({iconUrl: "/images/voodoo-48.png", iconSize: [24,24], iconAnchor:[22,16]})
        lat = e.address?.latitude
        long = e.address?.longitude
        if (lat? && long?)
          lat += Math.random() * 0.00005
          long += Math.random() * 0.00005

          iconhtml = Meteor.render( -> Template.eventmapmarker(e))
          icondivchild = L.DomUtil.create("div","lbqs")
          icondivchild.appendChild(iconhtml)
          #$(document.body).append(icondivchild)
          self.icondivchild = icondivchild
          require "TomDivIcon", (tomDivIcon) ->
            icon = tomDivIcon(
              className: "blabla"
              iconSize: [40,60]
              iconAnchor: [20,60]
              div: icondivchild
            )
            e.expanded = true
            #html = Template.contentitem(e)
            m = L.marker([lat, long], {icon: icon}).addTo(self.clusterer).on(
              "click": (info) ->
                #console.log("info", m._popup)
                if m._popup?
                  return
                NProgress.start()
                model.subscribeDetails(e._id, ->
                  data = model.getContent({query: e._id, details: true}).fetch()[0]
                  #console.log(data)
                  data.expanded = true
                  content = Meteor.render( ->
                    Template.contentitem(data)
                  )
                  div = L.DomUtil.create("div","lbqs")
                  div.appendChild(content)

                  #console.log("clickcontent",div)
                  m.bindPopup(div).openPopup()
                  NProgress.done()
                )
                #popup = L.popup().setLatLng(info.latlng).setContent(content).openOn(map)
            )
            self.markers[e._id] = m
      removed: (e) ->
        self.map.removeLayer(self.markers[e._id])
        delete self.markers[e._id]
      changed: (e) ->

        #self.markers[e._id].setPopupContent(Meteor.render( -> Template.contentitem(e)))   #unless self.markers[e._id]._popup?
        #  return
        #console.log("changed", e)
        #console.log(self.markers[e._id])
        #console.log("changed",Meteor.render( -> Template.contentitem(e)))
  self.initializeMap = _.once ->
    console.log("loading mapbox external js + css")
    Meteor.Loader.loadJs("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.js", ->
     Meteor.Loader.loadJs("/js/leaflet.markercluster.js", ->
      console.log("loaded mapbox js")
      Meteor.Loader.loadCss("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.css")
      self.map = L.mapbox.map('eventmapcontainer', 'examples.a4c252ab').setView([-23.55, -46.6333], 13)
      require "TomDivIcon", (tomDivIcon) ->
        self.clusterer = new L.MarkerClusterGroup(
          animateAddingMarkers: true
          maxClusterRadius: 20
          spiderfyOnMaxZoom: true
          iconCreateFunction: (cluster) ->
            children = cluster.getAllChildMarkers()
            nochildren = children.length
            childopacity = 1.0/children.length + 0.2

            divParent = $("<div data-toggle='tooltip' data-placement='right' data-original-title='"+nochildren+" events in this region' ></div>")[0]
            divCC = L.DomUtil.create("div","eventmapclustercontainer")

            _.each(_.sample(children,3), (c) ->
              divChild = L.DomUtil.create("div","eventmapclusterchild")
              divChild.appendChild(c.options.icon.options.div.children[0].cloneNode(true))
              divCC.appendChild(divChild)
              #console.log("childchild",c.options.icon.options.div)

            )
            divParent.appendChild(divCC)
            divText = L.DomUtil.create("div","eventmapclustertext")
            divText.innerText = nochildren
            divParent.appendChild(divText)
            Meteor.setTimeout( ->
              $(".eventmapclustertooltip").tooltip()
            ,1000)
            tomDivIcon({div: divParent, className: "eventmapclustertooltip", iconSize: L.point(40,60), iconAnchor: [20,60]})
        )
      self.addEventsToMap(self.map, self.clusterer)
      self.map.addLayer(self.clusterer)
     )
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
      yieldTemplates:
        'navbar': {to: 'navbar'}

