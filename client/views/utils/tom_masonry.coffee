define "TomMasonry",[], ->
  self = {

    windowHeight: -> Meteor.RwindowSize.height

    # find maximal width of window to snap down to the masonry column width
    widthToMasonryCol: (width) ->
      Math.floor(width / (self.columnWidth+self.columnGutter*2/3)) * (self.columnWidth+ self.columnGutter*2/3)

    windowWidthToMasonryCol: -> self.widthToMasonryCol Meteor.RwindowSize.width
    columnHeight: 115
    columnWidth: 115

  }


  Meteor.startup ->
    Session.set("windowHeight", $(window).height())
    Session.set("windowWidth", $(window).width())
    $(window).resize ->
      Session.set("windowHeight", $(window).height())
      Session.set("windowWidth", $(window).width())
      #self.debouncedRelayout()

  return self