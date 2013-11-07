define "ContentgridController", ["VoodoocontentModel","Config","PackeryMeteor","ContentCommon","ContentItem"], (model,config,packery,contentCommon, contentItem) ->

  console.log("loading content grid")
  self = {}

  self.subscribeFilteredSortedContent = (callback)  ->
    content_sort = Session.get("content_sort")
    if content_sort?
      sort = {}
      sort[content_sort.name] = content_sort.order
    filters =  {}
    _.each Session.get("active_content_filters"), (f) ->
      filters["type"] = f
    #filters.post_date = { "$gte": (new Date()).toISOString() }
    #filters["address.city"] = "São Paulo"

    #filters["num_app_users_attending"] = {"$gte": 1}

    options =
      query: filters
      sort: sort
      blockno: Session.get("blockvisible")
    model.subscribeContent(options, -> Session.set("contentoptions", options); callback() if callback? )#, -> Session.set("voodoocontent", model.getContent()))

  self.contentTypes = contentCommon.contentTypes;

  self.sortTypes = [
    {name: "post_date", title:"Post Date", icon:"glyphicon glyphicon-calendar", accessor: (e) -> e?.post_date}
    {name: "like_count", title:"Likes", icon:"glyphicon glyphicon-heart", accessor: (e) -> e?.like_count}
  ]
  Session.set("blockvisible",1)



  Template.contentgrid.voodoocontent = -> model.getContent(Session.get("contentoptions"))

  self.setupReactiveContentSubscription = _.once( ->
    Deps.autorun ->
      console.log("subscribing to content")
      self.subscribeFilteredSortedContent( ->
        NProgress.done();
      )
      NProgress.start();
  )

  Template.contentgrid.rendered = ->
    self.setupReactiveContentSubscription();




  #infinite scroll


  Template.contentgrid.moreResults = ->
    model.lastItemCount() >= model.lastLimit;

  showMoreVisible = _.debounce( ->
    threshold = undefined
    target = $("#showMoreResults")
    return unless target.length
    threshold = $(window).scrollTop() + $(window).height() - target.height()
    if target.offset().top < threshold
      unless target.data("visible")
        # console.log('target became visible (inside viewable area)');
        target.data "visible", true
        Session.set "blockvisible", Session.get("blockvisible") + 1
    else

      # console.log('target became invisible (below viewable arae)');
      target.data "visible", false  if target.data("visible")
  , 10)
  Meteor.startup ->
    $(window).scroll(showMoreVisible);
  return self
