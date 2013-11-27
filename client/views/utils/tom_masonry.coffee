define "TomMasonry",[], ->
  self = {

    windowHeight: -> Session.get("windowHeight")

    # find maximal width of window to snap down to the masonry column width
    windowWidthToMasonryCol: ->
      Math.floor(Session.get("windowWidth") / (self.columnWidth+self.columnGutter*2/3)) * (self.columnWidth+ self.columnGutter*2/3)

    columnWidth: 230
    columnGutter: 0

    init: (container) ->
      self.ms = new Packery(container[0],
        itemSelector: ".masonrycontainer"
        columnWidth: self.columnWidth + self.columnGutter*2/3
        gutter: self.columnGutter*1/3
        isFitWidth: true
        stamp: ".stamp"
        #transitionDuration: 0.5
      )
    debouncedRelayout: _.debounce( (reload=false) ->
      if (self.ms)
        if (reload)
          self.ms.reload()
        self.ms.layout()
    ,300)

    remove: (item) -> self.ms.remove(item[0])

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