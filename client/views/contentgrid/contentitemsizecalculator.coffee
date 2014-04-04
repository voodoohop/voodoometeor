require ["TomMasonry","VoodoocontentModel"], (tomMasonry, model) ->

  contentWidthInGrid= (item) ->
      metadata = item.metaData()
      if (metadata.allowDynamicAspectRatio and (origWidth = item.embedlyData?[0]?.width))
        origHeight = item.embedlyData[0].height
        return calcMaxSize(origWidth, origHeight, metadata)[0]
      return metadata.width

  contentHeightInGrid= (item) ->
      metadata = item.metaData()
      #console.log("getting content height in grid",metadata,item)
      if (metadata.allowDynamicAspectRatio and item.embedlyData?[0]?)
        origHeight = item.embedlyData[0].height
        origWidth = item.embedlyData[0].width
        #console.log("origWidth,height",origWidth, origHeight)
        maxHeight = calcMaxSize(origWidth, origHeight, metadata)[1]
        #console.log("maxHeight",maxHeight)
        if (metadata.minHeight?)
          maxHeight=Math.max(metadata.minHeight,maxHeight)
        return maxHeight
      return metadata.height






  model.contentCollection.helpers

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




