define "NavStamper", ["TomMasonry"], (tomMasonry) ->

  self = {
    init: (el, topoffset=150, callbacks) ->
      originalelpos = el.offset().top # take it where it originally is on the page
      #run on scroll
      isfadingout = false;
      ismoving = false;
      stamped = true;
      #tomMasonry.reStamp(el)

      stamper = (isInStampArea) ->
        if !isInStampArea and stamped
          tomMasonry.unStamp(el, ->
            callbacks.onUnstamped(el) if callbacks.onUnstamped?
          )
          stamped = false

        if isInStampArea and !stamped
          tomMasonry.reStamp(el, ->
            callbacks.onStamped(el) if callbacks.onStamped?
          )
          stamped = true



      doFadingInAndStamping = _.debounce( ->
        #elpos = el.offset().top # take current situation

        windowpos = $(window).scrollTop()
        isInStampArea = windowpos < topoffset
        if (!isInStampArea)
          stamper(isInStampArea)
        #ismoving = true;
        #el.stop()
        topos = if isInStampArea then originalelpos else windowpos + originalelpos
        el.stop()
        el.animate({top: topos, opacity: 0.6}, 300, 'swing', ->
          el.animate({opacity: 1}, 200, 'swing', ->
            ismoving = false
            if (isInStampArea)
              stamper(isInStampArea)
          )
        )
      , 150)

      $(window).scroll ->
        #console.log(ismoving, isfadingout)
        windowpos = $(window).scrollTop()
        if (true or (!isfadingout and !ismoving))
          isfadingout = true
          el.stop()
          el.animate({ opacity: 0.4 }, 100, "swing", ->
            isfadingout = false
            ismoving = true
            doFadingInAndStamping()
          )



  }
  return self