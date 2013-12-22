define "TomMasonry_Isotope",[], ->
  self = {

    windowHeight: -> Session.get("windowHeight")

    # find maximal width of window to snap down to the masonry column width
    windowWidthToMasonryCol: ->
      Math.floor(Session.get("windowWidth") / (self.columnWidth+self.columnGutter*2/3)) * (self.columnWidth+ self.columnGutter*2/3)

    columnWidth: 115
    columnGutter: 0
    addItems: (items) -> self.ms.addItems(items)
    appended: (div) -> self.container.isotope("appended",div)
    init: (container) ->
      this.container = container
      self.ms = container.isotope(
        itemSelector: ".masonrycontainer"
        columnWidth: self.columnWidth + self.columnGutter*2/3
        gutter: self.columnGutter*1/3
        isFitWidth: true
        stamp: ".stamp"
        layoutMode: "perfectMasonry"
        perfectMasonry: {
          columnWidth: self.columnWidth + self.columnGutter*2/3
          rowHeight: 115
        }
        #transitionDuration: 0.5
      )
    debouncedRelayout: _.debounce( (reload=false) ->
      if (self.ms)
        if (reload)
          self.container.isotope("reloadItems")
        self.container.isotope("reLayout")
    ,300)

    remove: (item) -> this.container.isotope("remove",item)

    unStamp: (element,callback) ->
      self.ms.unstamp(element);
      callback() if callback?
      self.debouncedRelayout(false);
    reStamp: (element, callback) ->
      self.ms.stamp(element);
      callback() if callback?
      self.debouncedRelayout(false);
  }


  Meteor.startup ->
    Session.set("windowHeight", $(window).height())
    Session.set("windowWidth", $(window).width())
    $(window).resize ->
      Session.set("windowHeight", $(window).height())
      Session.set("windowWidth", $(window).width())
      self.debouncedRelayout()

  return self