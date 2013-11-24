require ["ContentCommon","ContentgridController"], (contentCommon, controller) ->

  Rfilters = controller.RsortFilters

  Template.filterbar.helpers
    contentTypes: -> contentCommon.contentTypes
    filters: -> contentCommon.filterOptions
    sortTypes: -> contentCommon.sortTypes
    activeContentFilters: -> Rfilters.active_content_filters
    activeContentFilter: -> if _.contains(Rfilters.active_content_filters,this.name) then "active" else ""

  Template.userbar.helpers
    user: -> Meteor.user()
    userfirstname: ->
      return null unless Meteor.user()?
      Meteor.user().profile.name.split(" ")[0]
    profileimg: ->
      return null unless Meteor.user()?
      "http://graph.facebook.com/"+Meteor.user().services.facebook.id+"/picture"

  Rfilters.filter = contentCommon.constructFilters("0.0.0")

  Template.filterbar.events =
    'click .sort_filter': () ->
      Rfilters.blockvisible= 1
      content_sort = Rfilters.content_sort
      Rfilters.content_sort = {
        name: this.name
        order: if content_sort.name == this.name then content_sort.order * -1 else 1
      }
      console.log("new content_sort", Rfilters.content_sort)

  #Meteor.Router.to("/eventdetail/"+this._id)

    'click .content_filter': () ->
      currobj = this
      sub = null
      path=this.name
      while currobj.subFilters? or currobj.sortFilters?
        sub = currobj.subFilters ? currobj.sortFilters
        console.log("sub",sub[0])
        path+="."+sub[0].name
        currobj = sub[0]
      console.log("path",path)
      filter = contentCommon.constructFilters(path)
      console.log("constructed filter",filter)
      #filters = Rfilters.active_content_filter
      #if (_.contains(filters,this.name))
      #  filters = _.without filters, this.name
      #else
      #  filters.push(this.name)
      Rfilters.filter = filter
      Rfilters.blockvisible = 1

