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
    model.subscribeContent(options, ->
      Session.set("contentoptions", options);
      callback() if callback?
    )

  self.contentTypes = contentCommon.contentTypes;


  Session.set("blockvisible",1)



  #Template.contentgrid.voodoocontent = -> model.getContent(Session.get("contentoptions"))

  self.setupReactiveContentSubscription = _.once( ->
    Deps.autorun ->
      console.log("subscribing to content")
      self.subscribeFilteredSortedContent( ->
        NProgress.done();
      )
      NProgress.start();
  )

  debouncedMasonryRelayout = _.debounce( ->
    self.ms.layout()
  ,200)

  Template.contentgrid.rendered = _.once ->
    self.setupReactiveContentSubscription();
    container = $("#contentgridcontainer")
    self.ms = new Masonry($("#contentgridcontainer")[0],
      itemSelector: ".masonrycontainer"
      columnWidth: contentCommon.columnWidth+contentCommon.columnGutter*2/3
      gutter: contentCommon.columnGutter*1/3
      isFitWidth: true
    )
    contentItem.ms = self.ms;

    # masonrify contenitem collection changes

    model.getContent({query: {}}).observe
      addedAt: (e, index, before) ->
        #console.log("added", e, index, before)
        content = Meteor.render( ->
          Template.contentitem(e)
        )
        appenddiv = $("<div class='masonrycontainer' id='msnry_"+e._id+"'/>").append(content)
        if (before == null)
          container.append(appenddiv)
          self.ms.appended(appenddiv)
        else
          $("#msnry_"+before._id).before(appenddiv)
          self.ms.addItems(appenddiv)
          self.ms.reload()
          debouncedMasonryRelayout()
      removed: (e) ->
        console.log("removed")
        self.ms.remove($("#msnry_"+e._id)[0])
        debouncedMasonryRelayout()
      movedTo: (doc, fromIndex, toIndex, before) ->
        console.log("moved", doc, fromIndex, toIndex, before)
        if (before == null)
          container.append($("#msnry_"+e._id))
          self.ms.reload()
          debouncedMasonryRelayout()
        else
          $("#msnry_"+before._id).before($("#msnry_"+e._id))
          self.ms.reload()
          debouncedMasonryRelayout()
      changed: (newDoc, oldDoc) ->
        console.log("changed",newDoc,oldDoc)
        content = Meteor.render( ->
          Template.contentitem(newDoc)
        )
        $("#"+newDoc._id).replaceWith(content)


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
