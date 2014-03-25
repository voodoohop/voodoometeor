define "NavBar", ["ContentCommon", "TomMasonry"], (contentCommon, masonry) ->
  console.log("required navbar")
  self = {}
  self.items= []
  self.initNavbar = (container, Rfilters) ->

    Template.navitem.helpers
      isSelected: ->
        this.name == Rfilters.path?[0]



    Template.navitem.events
      'click .sort_filter':  ->
        Rfilters.blockvisible= 1
        content_sort = Rfilters.content_sort
        Rfilters.content_sort = {
          name: this.name
          order: if content_sort.name == this.name then content_sort.order * -1 else 1
        }
        console.log("new content_sort", Rfilters.content_sort)

      'click .content_filter': (param1,param2,param3) ->
        console.log("clicked content_filter",this,param1,param2,param3)
        currobj = this

        sub = null
        path=[this.name]
        while currobj.subFilters? or currobj.sortFilters?
          sub = currobj.subFilters ? currobj.sortFilters
          console.log("sub",sub[0])
          path.push(sub[0].name)
          currobj = sub[0]
        console.log("path",path)
        filter = contentCommon.constructFilters(path)
        console.log("constructed filter",filter)
        #filters = Rfilters.active_content_filter
        #if (_.contains(filters,this.name))
        #  filters = _.without filters, this.name
        #else
        #  filters.push(this.name)
        Rfilters.path = path
        Rfilters.filter = filter
        Rfilters.blockvisible = 1


    Template.navboxestomasonry.navBoxes = ->
      contentCommon.filterOptions

  console.log("returned navbar", self)
  return self