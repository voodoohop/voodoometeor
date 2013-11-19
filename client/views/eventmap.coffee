define "EventMap", ["VoodoocontentModel", "ContentItem", "LeafletUtils"], (model, contentItem, leafletUtils) ->
  self = {}


  self.eventQuery =
    type: "event"
    #num_app_users_attending:
    #  $gte: 5


  self.debouncedUpdateEvents = _.debounce( ->
    Session.set("eventsmapquery", self.eventQuery)
  ,500)

  self.changeEventQuery = (options) ->
    _.each options, (val, key) ->
      self.eventQuery[key] = val
    self.debouncedUpdateEvents()

  self.updateContentQueryBasedOnMapBounds = _.debounce( (bounds) ->
    self.changeEventQuery
      "address.latitude":
        "$lte": bounds.getNorth()+0.1
        "$gte": bounds.getSouth()-0.1
      "address.longitude":
        "$gte": bounds.getWest()-0.1
        "$lte": bounds.getEast()+0.1
  ,500)


  Template.contentitem_event.helpers model.helpers
  Template.eventmapmarker.helpers contentItem.helpers
  Template.eventmap.events =
    'change, keyup #maptextfilter': (evt) ->
      val = $(evt.target).val();
      self.changeEventQuery
        $or: [{description: { $regex: val, $options:"i" }}, {title: { $regex: val, $options:"i" }}]

  individualMarkerAdd = (marker) -> self.clusterer.addLayer(marker)
  self.batchifiedMarkerAdd = batchify( individualMarkerAdd , (markers) ->
    console.log("batch adding "+markers.length+" markers")
    self.clusterer.addLayers(_.flatten(markers))
    self.addEventMapMarkerTooltips();
  , 500)

  Template.eventmap.markerscount = ->
    Session.get("markerscount")
  Session.set("markerscount",0)

  self.addEventsToMap = (map) ->

    #    title: { $regex: "oodoo", $options:"i" }
    #    post_date:
    #    "$gte": moment().subtract("hours",8).toISOString()
    #    "$lte": moment().add("days",1).t
    self.updateContentQueryBasedOnMapBounds(self.map.getBounds())
    Deps.autorun ->
      console.log("events map query changed... resubscribing", Session.get("eventsmapquery"))
      NProgress.start()
      model.subscribeContent({query: Session.get("eventsmapquery")}, ->
        console.log("done subscribing")
        NProgress.done()
      )

    eventscursor = model.getContent()
    eventscursor.observe leafletUtils.markermanager(self.batchifiedMarkerAdd, self.clusterer,
      popupCreate: (e,div, done) ->
        NProgress.start()
        self.detailSubscription = model.subscribeDetails(e._id, ->
          data = model.getContent({query: e._id, details: true}).fetch()[0]
          data.expanded = true
          content = Meteor.render( ->
            Template.contentitem(data)
          )
          div.appendChild(content)
          done()
          NProgress.done()
        )
      popupClose: -> self.detailSubscription.stop()
    )


  self.initializeMap = _.once ->
    console.log("loading mapbox external js + css")
    Meteor.Loader.loadJs("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.js", ->
     Meteor.Loader.loadJs("/js/leaflet.markercluster.js", ->
      console.log("loaded mapbox js")
      Meteor.Loader.loadCss("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.css")
      self.map = L.mapbox.map('eventmapcontainer', 'examples.map-9ijuk24y').setView([-23.55, -46.6333], 13)  #examples.a4c252ab
      self.startWatchingGeolocation()
      require "TomDivIcon", (tomDivIcon) ->
        self.tomDivIcon = tomDivIcon
        self.clusterer = new L.MarkerClusterGroup(
          #removeOutsideVisibleBounds: false
          animateAddingMarkers: true
          maxClusterRadius: 20
          spiderfyOnMaxZoom: true
          iconCreateFunction: (cluster) ->
            children = cluster.getAllChildMarkers()
            nochildren = children.length
            childopacity = 1.0/children.length + 0.2
            locations = {}
            _.each(children, (c) ->
              if c.data.location?
                locations[c.data.location] = (locations[c.data.location] ? 0) + 1
            )

            if _.keys(locations).length > 4
              locations = {}
              _.each(children, (c) ->
                if c.data.address.city?
                  locations[c.data.address.city] = (locations[c.data.address.city] ? 0) + 1
              )

            locationtext = _.keys(locations).join(", ")
            divParent = $("<div data-toggle='tooltip' data-placement='right' data-original-title='"+nochildren+" events in this region at "+locationtext+"' ></div>")[0]
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

        self.map.on("zoomend", ->
          self.addEventMapMarkerTooltips();
          $(".tooltip").hide();
          self.updateContentQueryBasedOnMapBounds(self.map.getBounds())
        )
        self.map.on("moveend", ->
          $(".tooltip").hide();
          self.updateContentQueryBasedOnMapBounds(self.map.getBounds())
        )
     )
    )


  self.addEventMapMarkerTooltips = _.debounce( ->
    Meteor.setTimeout( ->
      $(".eventmapmarkertooltip").tooltip()
      console.log("adding tooltips to eventmarker")
    ,500)
  , 1000)

  Template.eventmap.rendered = _.once ->
    self.initializeMap()

    self.updateRangeSliderLabelsAndEventsQuery = ->
        values = $("#eventmapdaterangeslider").val();
        #console.log(values)
        #self.popoverleft.setContent(values[0])
        #self.popoverright.setContent(values[1])
        startdate = moment().add("days",values[0])
        enddate = moment().add("days",values[1])
        $("#eventmapstartdate").html(startdate.calendar().split(" ")[0])
        $("#eventmapenddate").html(enddate.calendar().split(" ")[0])
        self.changeEventQuery
          post_date:
            "$gte": startdate.subtract("hours",4).toISOString()
            "$lt": enddate.toISOString()


    $("#eventmapdaterangeslider").noUiSlider(
      range: [0,100]
      start: [0,1]
      margin: 1
      step: 1
      connect: true
      slide: self.updateRangeSliderLabelsAndEventsQuery
    )

    $(".noUi-handle-lower").popover(
      html: true
      content: "<div id='eventmapstartdate' style='width: 80px'>hey</div>"
      trigger: "manual"
      placement: "left"
    ).popover('show')

    $(".noUi-handle-upper").popover(
      html: true
      content: "<div id='eventmapenddate' style='width: 80px'>hey</div>"
      trigger: "manual"
      placement: "right"
    ).popover('show')

    self.updateRangeSliderLabelsAndEventsQuery()



  self.startWatchingGeolocation = ->
   if navigator.geolocation
    console.log("watching geolocation")
    navigator.geolocation.watchPosition ((p) ->

      if not p.coords.latitude or not p.coords.longitude
        console.warn "Position doesn't have lat/lng. Ignoring", pos
        return # we don't want yer lousy geolocation anyway.

      console.log("user pos", p)
      pos = _.clone(p.coords)
      pos.timestamp = p.timestamp;
      # $.extend(true, {}, pos); // Fix FF error 'Cannot modify properties of a WrappedNative'

      Session.set("geolocation",pos);

      unless @hasCenteredMap
        zoom = 16
        self.map.setView [pos.latitude, pos.longitude], zoom
        @hasCenteredMap = true
    ), null,
      enableHighAccuracy: false
      maximumAge: 60000
      timeout: 100000
   else
    console.log "geolocation not supported"
   #update user geolocation
   Deps.autorun ->
    if (Meteor.user())
      Meteor.users.update(Meteor.user()._id,
       $set:
         "geolocation": Session.get("geolocation")
      )

  return self

require "EventMap", (eventMap) ->
  Router.map ->
    this.route 'eventmap',
      path:'/eventmap'
      template: 'eventmap'
      layoutTemplate: 'mainlayout'
      yieldTemplates:
        'navbar': {to: 'navbar'}

