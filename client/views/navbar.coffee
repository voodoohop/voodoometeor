require ["ContentCommon","ContentgridController"], (contentCommon, controller) ->

  Rfilters = controller.RsortFilters

  Template.navbar.helpers
    contentTypes: -> contentCommon.contentTypes
    sortTypes: -> contentCommon.sortTypes
    activeContentFilters: -> Rfilters.active_content_filters
    activeContentFilter: -> if _.contains(Rfilters.active_content_filters,this.name) then "active" else ""
    user: -> Meteor.user()
    userfirstname: ->
      return null unless Meteor.user()?
      Meteor.user().profile.name.split(" ")[0]
    profileimg: ->
      return null unless Meteor.user()?
      "http://graph.facebook.com/"+Meteor.user().services.facebook.id+"/picture"
  Rfilters.active_content_filters = []
  Rfilters.content_sort = {name: "num_app_users_attending", order: -1}

  Template.navbar.events =
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
      filters = Rfilters.active_content_filters ? []
      if (_.contains(filters,this.name))
        filters = _.without filters, this.name
      else
        filters.push(this.name)
      Rfilters.active_content_filters = filters
      Rfilters.blockvisible = 1
      console.log(filters)
