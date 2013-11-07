require "ContentCommon", (contentCommon) ->

  Template.navbar.helpers
    contentTypes: -> contentCommon.contentTypes
    sortTypes: -> contentCommon.sortTypes
    activeContentFilters: -> Session.get("active_content_filters")
    activeContentFilter: -> if _.contains(Session.get("active_content_filters"),this.name) then "active" else ""
    user: -> Meteor.user()
    userfirstname: ->
      return null unless Meteor.user()?
      Meteor.user().profile.name.split(" ")[0]
    profileimg: ->
      return null unless Meteor.user()?
      "http://graph.facebook.com/"+Meteor.user().services.facebook.id+"/picture"
  Session.set("active_content_filters",[])
  #Session.set("content_sort", {name: "post_date", order: 1})
  Session.set("content_sort", {name: "num_app_users_attending", order: -1})

  Template.navbar.events =
    'click .sort_filter': () ->
      content_sort = Session.get("content_sort")
      Session.set("content_sort",
        name: this.name
        order: (if content_sort.name == this.name then content_sort.order * -1 else 1)
      )
      Session.set("blockvisible",1)
      console.log(Session.get("content_sort"))

  #Meteor.Router.to("/eventdetail/"+this._id)

    'click .content_filter': () ->
      filters = Session.get("active_content_filters") ? []
      if (_.contains(filters,this.name))
        filters = _.without filters, this.name
      else
        filters.push(this.name)
      Session.set("active_content_filters",filters)
      Session.set("blockvisible",1)
      console.log(filters)
