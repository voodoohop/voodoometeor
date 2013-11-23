define "TomMasonry",[], ->
  self = {

    windowHeight: -> Session.get("windowHeight")

    # find maximal width of window to snap down to the masonry column width
    windowWidthToMasonryCol: ->
      Math.floor(Session.get("windowWidth") / (self.columnWidth+self.columnGutter*2/3)) * (self.columnWidth+ self.columnGutter*2/3)

    columnWidth: 115
    columnGutter: 3

    init: (container) ->
      self.ms = new Masonry(container[0],
        itemSelector: ".masonrycontainer"
        columnWidth: self.columnWidth + self.columnGutter*2/3
        gutter: self.columnGutter*1/3
        isFitWidth: true
      )
    debouncedRelayout: _.debounce( (reload=false) ->

      if (self.ms)
        if (reload)
          self.ms.reload()
        self.ms.layout()
    ,200)
    remove: (item) -> self.ms.remove(item[0])
  }


  Meteor.startup ->
    Session.set("windowHeight", $(window).height())
    Session.set("windowWidth", $(window).width())
    $(window).resize ->
      Session.set("windowHeight", $(window).height())
      Session.set("windowWidth", $(window).width())
      self.debouncedRelayout()

  return self