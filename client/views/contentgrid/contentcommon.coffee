define "ContentCommon", ["TomMasonry"], (tomMasonry) ->

  sortTypes =
    post_date_desc:
      title:"Post Date"
      name:"post_date_desc"
      sort:[["post_date","desc"]]
      icon:"glyphicon glyphicon-calendar"
    post_date_asc:
      title:"Post Date"
      name:"post_date_asc"
      sort:[["post_date","asc"]]
      icon:"glyphicon glyphicon-calendar"
    num_app_users_attending:
      title:"Likes"
      name: "num_app_users_attending"
      sort: [["num_app_users_attending","desc"]]
      icon:"glyphicon glyphicon-heart"
    isVoodoo:
      title:"Voodoo"
      name: "isVoodoo"
      sort: [["isVoodoo","desc"], ["voodooOrder","asc"]]


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







    filterOptions: [
      {
        name:"voodoohop"
        title:"VOODOO"
        query:
          blocked: {$ne: true}
          $or: [
            {isVoodoo: true}
            #$and: [
            #  #num_app_users_attending: {"$gte": 50}
            #  {featured: true}
            #  {post_date: {$gte: moment().minutes(0).seconds(0).subtract(12,"hours").toISOString() }}
            #]
          ]
        titleclass: "voodoologo"
        icon: "icon-voodoologo"
        disabled: false
        sortFilters: [sortTypes.isVoodoo]
#        subFilters: [
#          {
#            title :"All"
#            name: "all"
#            icon: "icon-voodoologo"
#            query:
#              $or: [{type: "video"},{type: "event"}, {type: "photo"}]
#            sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
#          }
#          {
#            title:"Music"
#            name:"music"
#            icon: "icon-voodoomusic"
#            query:
#              $and: [{type: "video"},{"embedlyData.html": {$exists: true}}]
#            sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
#          }
#          {
#            title: "Artists"
#            name: "artists"
#            icon: "icon-voodooartists"
#            query:
#              type: "photo"
#              artistprofile: true
#            sortFilters: [sortTypes.post_date_desc]
#          }
#        ]
      }
#      {
#        title:"Media"
#        name: "media"
#        icon: "icon-voodoomedia"
#        query:
#          $or: [{type: "photo"}, {type: "video"}]
#        subFilters: [
#          {
#            title:"Photos"
#            name: "photo"
#            query: {type: "photo"}
#            icon: "icon-voodoopictures"
#            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
#          }
#          {
#            title:"Radio"
#            name: "radio"
#            query: {type: "radio"}
#            icon: "icon-voodooradio"
#            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
#          }
#          {
#            title:"Links"
#            name: "links"
#            query: {type: "link"}
#            icon: "glyphicon glyphicon-link"
#            sortFilters: [sortTypes.num_app_users_attending, sortTypes.post_date_desc]
#          }
#        ]
#        sortFilters: [sortTypes.post_date_desc, sortTypes.num_app_users_attending]
#      }
      {
        title:"Calendar"
        name:"events"
        icon:"icon-voodooevent"
        displayDaysInGrid: true
        query:
          blocked: {$ne: true}, type: "event", post_date: {$gte: moment().minutes(0).seconds(0).subtract(12,"hours").toISOString() }, num_app_users_attending: {"$gt": 5}
        sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
      }
#      {
#        title:"Map"
#        name:"map"
#        icon:"icon-voodoomap"
#        disabled: true
#        query:
#          blocked: {$not: true}, type: "event", post_date: {$gte: moment().minutes(0).seconds(0).toISOString() }
#        sortFilters: [sortTypes.post_date_asc, sortTypes.num_app_users_attending]
#      }
      {
        title:"Wall"
        name:"wall"
        icon: "glyphicon glyphicon-link"
        disabled: false
        query:
          wallPost: true
        sortFilters: [sortTypes.post_date_desc]
      }

    ]
    initpath: ["events"]

    getTitleFromPath: (path) ->
      filterOption = _.findWhere(self.filterOptions, {name: path[0]})
      return filterOption.title

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
      console.log("constructed query:",q)
      sortFilter = {}
      if (q.sortFilter)
        sortFilter = q.sortFilter.sort
      return {query: {$and: q.query}, sortFilter: sortFilter}

  }
  return self;

