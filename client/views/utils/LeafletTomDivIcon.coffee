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
