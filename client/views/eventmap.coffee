define "EventMap", ["VoodoocontentModel", "ContentItem"], (model, contentItem) ->
  self = {}
  self.markers = {}

  self.eventQuery =
    type: "event"


  self.debouncedUpdateEvents = _.debounce( ->
    Session.set("eventsmapquery", self.eventQuery)
  ,500)

  self.changeEventQuery = (options) ->
    _.each options, (val, key) ->
      self.eventQuery[key] = val
    self.debouncedUpdateEvents()




  Template.contentitem_event.helpers model.helpers
  Template.eventmapmarker.helpers contentItem.helpers
  Template.eventmap.events =
    'change, keyup #maptextfilter': (evt) ->
      val = $(evt.target).val();
      self.changeEventQuery
        $or: [
          title: { $regex: val, $options:"i" },
          description: { $regex: val, $options:"i" }
        ]


  self.cursorobserver =
      added: (e) ->
        id = e._id
        #console.log("added to map",e)
        #icon = new L.icon({iconUrl: "/images/voodoo-48.png", iconSize: [24,24], iconAnchor:[22,16]})
        lat = e.address?.latitude
        long = e.address?.longitude
        if (lat? and long?)
          lat += Math.random() * 0.00005
          long += Math.random() * 0.00005

          iconhtml = Meteor.render( -> Template.eventmapmarker(e))
          icondivchild = L.DomUtil.create("div","lbqs")
          icondivchild.appendChild(iconhtml)
          self.icondivchild = icondivchild
          icon = self.tomDivIcon(
            className: "blabla"
            iconSize: [40,60]
            iconAnchor: [20,60]
            div: icondivchild
          )
          e.expanded = true
          #html = Template.contentitem(e)
          subscription = null
          m = L.marker([lat, long], {icon: icon}).on(
            "click": (info) ->
              #console.log("info", m._popup)
              if m._popup?
                return
              NProgress.start()
              subscription = model.subscribeDetails(e._id, ->
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
            "popupclose": (e) ->
              subscription.stop()
          )

          #console.log(m)
          #console.log("clustererlatproblem",self.clusterer,m)
          self.clusterer.addLayer(m)
          self.markers[e._id] = m
      removed: (e) ->
        #console.log("deleting marker",self.markers[e._id])
        lat = e.address?.latitude
        long = e.address?.longitude
        unless (lat? and long?)
          return
        #console.log("removed",e._id)
        if self.markers[e._id]
          self.clusterer.removeLayer(self.markers[e._id])
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

  self.addEventsToMap = (map) ->

    #    title: { $regex: "oodoo", $options:"i" }
    #    post_date:
    #    "$gte": moment().subtract("hours",8).toISOString()
    #    "$lte": moment().add("days",1).t

    Deps.autorun ->
      console.log("events map query changed... resubscribing", Session.get("eventsmapquery"))
      model.subscribeContent({query: Session.get("eventsmapquery")})

    eventscursor = model.getContent()
    eventscursor.observe self.cursorobserver


  self.initializeMap = _.once ->
    console.log("loading mapbox external js + css")
    Meteor.Loader.loadJs("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.js", ->
     Meteor.Loader.loadJs("/js/leaflet.markercluster.js", ->
      console.log("loaded mapbox js")
      Meteor.Loader.loadCss("//api.tiles.mapbox.com/mapbox.js/v1.4.0/mapbox.css")
      self.map = L.mapbox.map('eventmapcontainer', 'examples.map-9ijuk24y').setView([-23.55, -46.6333], 13)  #examples.a4c252ab
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

  Template.eventmap.rendered = _.once ->
    self.initializeMap()

    self.updateRangeSliderLabelsAndEventsQuery = ->
        values = $("#eventmapdaterangeslider").val();
        console.log(values)
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
      placement: "top"
    ).popover('show')

    $(".noUi-handle-upper").popover(
      html: true
      content: "<div id='eventmapenddate' style='width: 80px'>hey</div>"
      trigger: "manual"
      placement: "right"
    ).popover('show')

    self.updateRangeSliderLabelsAndEventsQuery()

  return self

require "EventMap", (eventMap) ->
  Router.map ->
    this.route 'eventmap',
      path:'/eventmap'
      template: 'eventmap'
      layoutTemplate: 'mainlayout'
      yieldTemplates:
        'navbar': {to: 'navbar'}

