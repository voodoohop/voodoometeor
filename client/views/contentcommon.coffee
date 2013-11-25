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
      {name: "event", color:"#428bca", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true, width: 230, height: 280}
      {name: "video", color:"#f0ad4e", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: true, inlineplay: true,width: 460, height: 280, allowDynamicAspectRatio: true, maxWidth: 460, maxHeight: 480, minHeight: 150}
      {name: "photo", color: "#d9534f", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning", width: 345, height: 345, showtitle:true, allowDynamicAspectRatio: true, maxWidth: 460, maxHeight: 480}
      {name: "link", color: "#5bc0de",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info", width: 230, height: 140}
    ]



    filterOptions: [
      {
        name:"voodoohop"
        title:"VOODOOHOP"
        query:
          num_app_users_attending: {"$gte": 5}
        titleclass: "voodoologo"
        icon: "icon-voodoologo2"
        subFilters: [
          {
            title:"All"
            name:"all"
            query:
              $or : [
                {type: "event", post_date: {$gte: new Date().toISOString() }}
                {type: "photo"}
                {type: "video"}
                {type: "link"}
              ]
            sortFilters: [sortTypes.num_app_users_attending,sortTypes.post_date_asc]
          }
          {
            title:"Events"
            name:"events"
            query:
              {type: "event", post_date: {$gte: new Date().toISOString() }}

            sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
          }
          {
            title:"Media"
            name:"media"
            query:
              $or: [{type: "photo"}, {type: "video"}]
            sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
          }
          {
            title: "Artists"
            name: "artists"
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
        query:
          $or: [{type: "photo"}, {type: "video"}]
        icon: "glyphicon glyphicon-facetime-video"
        sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
      }
      {
        title:"Links"
        name: "links"
        query: {type: "link"}
        icon: "glyphicon glyphicon-link"
        sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
      }

    ]

    constructFilters: (filterSelectPath) ->
      tokenizedpath = filterSelectPath.split(".")
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
        if (filterOption.subFilters?)
          return recursiveConstructQuery(tokenizedpath, filterOption.subFilters, query)
        else
          if (filterOption.sortFilters?)
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

  self.helpers =
    bgcol: _.partial( (c) ->
      type = _.findWhere(c.contentTypes, {name: this.type})
      if (type.colorfromweekday)
        self.colors[moment(new Date(this.post_date)).day() % self.colors.length]
      else
        type.color
    , self)
    contentTypeMetaData: self.getContenttypeMetadata

    width: (showDetail) ->
      if (showDetail)
        return tomMasonry.windowWidthToMasonryCol(self)
      else
        return self.contentWidthInGrid(this)

    height: (showDetail) ->
      if (showDetail)
        tomMasonry.windowHeight()
      else
        #console.log("detheight", this)
        return self.contentHeightInGrid(this)

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
    return [Math.round(origWidth*multiplier), Math.round(origHeight * multiplier)];



  return self;

