define "NavBar", ["ContentCommon", "TomMasonry"], (contentCommon, masonry) ->
  console.log("required navbar")
  self = {}
  self.items= []
  self.initNavbar = (container, Rfilters) ->

    Template.navmasonryitems.helpers
      contentTypes: -> contentCommon.contentTypes
      filters: -> contentCommon.filterOptions
      sortTypes: -> contentCommon.sortTypes
      activeContentFilters: -> Rfilters.active_content_filters
      activeContentFilter: -> if _.contains(Rfilters.active_content_filters,this.name) then "active" else ""

    Template.navmasonryitem.helpers
      isSelected: ->
        console.log("checking if selected")
        this.name == Rfilters.path[0]

    Template.userbar.helpers
      user: -> Meteor.user()
      userfirstname: ->
        return null unless Meteor.user()?
        Meteor.user().profile.name.split(" ")[0]
      profileimg: ->
        return null unless Meteor.user()?
        "http://graph.facebook.com/"+Meteor.user().services.facebook.id+"/picture"

    #debouncedLayoutTemplate = _.debounce( ->
    #  masonry.ms.layoutItems(self.items, true)
    #,100)
    Template.navmasonryitem.rendered = ->
      #console.log("rendered item", this)
      #self.msnryitems = _.map(self.items, (i) -> masonry.ms.getItem(i))
      #console.log("relayouting", self.msnryitems)
      masonry.ms.layout()
      #masonry.debouncedRelayout();
        #  debouncedLayoutTemplate()
    Template.navmasonryitem.events =
      'click .sort_filter': () ->
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

    console.log("rendering nav items")
    _.each(contentCommon.filterOptions, (filter) ->
      item = Meteor.render( ->
          Template.navmasonryitem(filter)
      )
      appenddiv = $("<div class='masonrycontainer masonrybuttoncontainer' id='navbutton_"+filter.name+"'/>").append(item)
      container.append(appenddiv)

      masonry.ms.appended(appenddiv)
      self.items.push(appenddiv[0])
      #self.items.push($("#navbutton_"+filter.name)[0])
    )
    masonry.debouncedRelayout(true)

  console.log("returned navbar", self)
  return self