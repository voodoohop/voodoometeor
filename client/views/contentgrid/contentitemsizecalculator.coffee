require ["TomMasonry","VoodoocontentModel","Embedly"], (tomMasonry, model, embedly) ->

  contentWidthInGrid= (item) ->
      return item.overrideWidth if (item.overrideWidth)
      if (item.cols)
        return item.cols*tomMasonry.columnWidth
      if (item.link)
        origDimensions = embedly.getDefaultDimensions(item.link)
      metadata = item.metaData()
      if (metadata.allowDynamicAspectRatio and origDimensions?)
        return calcMaxSize(origDimensions[0], origDimensions[1], metadata)[0]
      return metadata.width

  contentHeightInGrid= (item) ->
      return item.overrideHeight if (item.overrideHeight)
      metadata = item.metaData()
      #console.log("getting content height in grid",metadata,item)
      if (item.link)
        origDimensions = embedly.getDefaultDimensions(item.link)
      if (metadata.allowDynamicAspectRatio and origDimensions)

        console.log("origWidth,height",origDimensions[0], origDimensions[1])
        maxHeight = calcMaxSize(origDimensions[0], origDimensions[1], metadata)[1]
        #console.log("maxHeight",maxHeight)
        if (metadata.minHeight?)
          maxHeight=Math.max(metadata.minHeight,maxHeight)
        return maxHeight
      return metadata.height






  model.registerHelpers

    widthInGrid: -> contentWidthInGrid(this)

    heightInGrid: -> contentHeightInGrid(this)

  calcMaxSize = (origWidth, origHeight, metadata) ->
    aspectRatio = origWidth/origHeight
    multiplier = null
    if (aspectRatio >= metadata.maxWidth/metadata.maxHeight)
      multiplier = metadata.maxWidth / origWidth
      #console.log("metadata", metadata, metadata.maxWidth,origWidth, metadata.maxWidth / origWidth)
      #console.log("mult",multiplier)
    else
      cHeight = 0
      colno = 0
      # hacky way to find max height
      while (cHeight <= metadata.maxHeight)
        colno++
        cWidth = colno * tomMasonry.columnWidth
        cHeight = cWidth / aspectRatio
      cols = colno - 1
      multiplier = cols*tomMasonry.columnWidth/origWidth
      #console.log("cols",cols,"mult", multiplier, metadata.maxHeight, origWidth, tomMasonry.columnWidth)
    height = Math.round(origHeight * multiplier)
    #console.log("multiplier after",multiplier);
    snapheight = Math.round(height/tomMasonry.columnHeight)*tomMasonry.columnHeight
    #console.log("calculated max width, height",[Math.round(origWidth*multiplier), snapheight], metadata)
    return [Math.round(origWidth*multiplier), snapheight];




