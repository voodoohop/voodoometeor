define "ContentCommon", ["TomMasonry"], (tomMasonry) ->

  sortTypes =
    post_date_desc:
      title:"Post Date"
      name:"post_date_desc"
      field:"post_date"
      direction: -1
      icon:"glyphicon glyphicon-calendar"
    post_date_asc:
      title:"Post Date"
      name:"post_date_desc"
      field:"post_date"
      direction: 1
      icon:"glyphicon glyphicon-calendar"
    num_app_users_attending:
      title:"Likes"
      name: "num_app_users_attending"
      direction: -1
      icon:"glyphicon glyphicon-heart"


  self = {

    colors: [
      "#5cb85c"
      "#5bc0de"
      "#f0ad4e"
      "#428bca"
      "#5cb85c"
      "#f0ad4e"
      "#d9534f"
    ]



    contentTypes: [
      {name: "event", color:"voodoocolor1", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true, width: 230, height: 200}
      {name: "video", color:"voodoocolor2", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: true, inlineplay: true,width: 460, height: 280, allowDynamicAspectRatio: true, maxWidth: 460, maxHeight: 480, minHeight: 150}
      {name: "photo", color: "voodoocolor3", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning", width: 345, height: 345, showtitle:true, allowDynamicAspectRatio: true, maxWidth: 460, maxHeight: 440}
      {name: "link", color: "voodoocolor4",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info", width: 230, height: 140}
      {name: "coverphoto", color: "voodoocolor5",title:null, icon:null, class:"label label-info", width: 575, height: 400, allowDynamicAspectRatio: true}
    ]



    filterOptions: [
      {
        name:"voodoohop"
        title:"VOODOOHOP"
        query:
          num_app_users_attending: {"$gte": 5}
        titleclass: "voodoologo"
        icon: "icon-voodoologo"
        subFilters: [
          {
            title :"All"
            name: "all"
            icon: "icon-voodoologo"
            query:
              $or: [{type: "video"},{type: "event"}, {type: "photo"}]
            sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
          }
          {
            title:"Music"
            name:"music"
            icon: "icon-voodoomusic"
            query:
              $or: [{type: "photo"}, {type: "video"}]
            sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
          }
          {
            title: "Artists"
            name: "artists"
            icon: "icon-voodooartists"
            query:
              type: "photo"
              artistprofile: true
            sortFilters: [sortTypes.post_date_desc]
          }
        ]
      }
      {
        title:"Media"
        name: "media"
        icon: "icon-voodoomedia"
        query:
          $or: [{type: "photo"}, {type: "video"}]
        subFilters: [
          {
            title:"Photos"
            name: "photo"
            query: {type: "photo"}
            icon: "icon-voodoopictures"
            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
          }
          {
            title:"Radio"
            name: "radio"
            query: {type: "radio"}
            icon: "icon-voodooradio"
            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
          }
          {
            title:"Links"
            name: "links"
            query: {type: "link"}
            icon: "glyphicon glyphicon-link"
            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
          }
        ]
        sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
      }
      {
        title:"Events"
        name:"events"
        icon:"icon-voodooevent"
        query:
          {type: "event", post_date: {$gte: new Date().toISOString() }}
        sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
      }
      {
        title:"Map"
        name:"map"
        icon:"icon-voodoomap"
        query:
          {type: "event", post_date: {$gte: new Date().toISOString() }}
        sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
      }

    ]
    initpath: ["voodoohop"]

    constructFilters: (path) ->
      tokenizedpath = _.clone(path)
      console.log(tokenizedpath)
      recursiveConstructQuery = (tokenizedpath, subobj, query= []) ->
        #console.log("reccq",tokenizedpath, subobj, query)
        current = tokenizedpath.shift()
        filterOption = null
        if (isNaN(current))
          filterOption = _.findWhere(subobj, {name: current})
        else
          filterOption = subobj[parseInt(current)]
        if filterOption.query
          query.push(filterOption.query)
        if (filterOption.subFilters? and tokenizedpath.length > 0)
          return recursiveConstructQuery(tokenizedpath, filterOption.subFilters, query)
        else
          if (filterOption.sortFilters? and tokenizedpath.length > 0)
            #console.log("getting sort option from path, obj", tokenizedpath,filterOption.sortFilters[parseInt(tokenizedpath[0])])
            sortFilter = null
            if (isNaN(tokenizedpath[0]))
              sortFilter = _.findWhere(filterOption.sortFilters, {name: tokenizedpath[0]})
            else
              sortFilter = filterOption.sortFilters[parseInt(tokenizedpath[0])]
            console.log("returning sort filter, tok path",tokenizedpath,)
            return {sortFilter: sortFilter, query: query}
          return {query: query};
      q = recursiveConstructQuery(tokenizedpath, self.filterOptions)
      sortFilter = {}
      if (q.sortFilter)
        sortFilter[q.sortFilter.field] = q.sortFilter.direction
      return {query: {$and: q.query}, sortFilter: sortFilter}


    contentWidthInGrid: (item) ->
      metadata = self.getContenttypeMetadata(item)
      if (metadata.allowDynamicAspectRatio and (origWidth = item.embedlyData?[0]?.width))
        origHeight = item.embedlyData[0].height
        return calcMaxSize(origWidth, origHeight, metadata)[0]
      return metadata.width

    contentHeightInGrid: (item) ->
      metadata = self.getContenttypeMetadata(item)
      if (metadata.allowDynamicAspectRatio and (origHeight = item.embedlyData?[0]?.height))
        origWidth = item.embedlyData[0].width
        maxHeight = calcMaxSize(origWidth, origHeight, metadata)[1]
        if (metadata.minHeight?)
          maxHeight=Math.max(metadata.minHeight,maxHeight)
        return maxHeight
      return metadata.height
  }

  self.getContenttypeMetadata =  _.partial( (c,ob = this) ->
    _.where(c.contentTypes, {name: ob.type })?[0]
  ,self)

  self.itemWidth = (item, showDetail) ->
      if (showDetail)
        return tomMasonry.widthToMasonryCol(6*tomMasonry.columnWidth)
      else
        return self.contentWidthInGrid(item)

  self.itemHeight = (item, showDetail) ->
      if (showDetail)
        tomMasonry.windowHeight()
      else
        #console.log("detheight", this)
        return self.contentHeightInGrid(item)


  self.helpers =
    bgcol: _.partial( (c) ->
      type = _.findWhere(c.contentTypes, {name: this.type})
      if (type.colorfromweekday)
        return "bgvoodoocolor"+([moment(new Date(this.post_date)).day() % 5+ 1] )
      else
        type.color
    , self)

    fgcol: _.partial( (c) ->
      type = _.findWhere(c.contentTypes, {name: this.type})
      if (type.colorfromweekday)
        return "fgvoodoocolor"+([moment(new Date(this.post_date)).day() % 5+ 1] )
      else
        type.color
    , self)

    contentTypeMetaData: self.getContenttypeMetadata(this)

    width: (showDetail) ->
      self.itemWidth(this, showDetail)
    height: (showDetail) ->
      self.itemHeight(this, showDetail)

  calcMaxSize = (origWidth, origHeight, metadata) ->
    aspectRatio = origWidth/origHeight
    multiplier = null
    if (aspectRatio >= metadata.maxWidth/metadata.maxHeight)
      multiplier = metadata.maxWidth / origWidth
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
    height = Math.round(origHeight * multiplier)
    snapheight = Math.floor(height/tomMasonry.columnHeight)*tomMasonry.columnHeight
    return [Math.round(origWidth*multiplier), snapheight];



  return self;

