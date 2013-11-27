define "ContentgridController", ["VoodoocontentModel","Config","PackeryMeteor","ContentCommon", "TomMasonry", "NavStamper"], (model,config,packery,contentCommon, tomMasonry, navStamper) ->

  console.log("loading content grid")
  self = {}

  self.RsortFilters = new ReactiveObject(["filter","blockvisible"])

  self.RsortFilters.blockvisible = 1

  self.RselectedItem = new ReactiveObject(["id","showingDetail","playingMedia"])

  self.RsubscribeFilteredSortedContent = (callback) ->
    self.subscribeFilteredSortedContent(self.RsortFilters, callback)

  self.subscribeFilteredSortedContent = (sortFilterOptions, callback)  ->
    console.log("subscribing",sortFilterOptions)

    options =
      query: sortFilterOptions.filter.query
      sort: sortFilterOptions.filter.sortFilter
      blockno: sortFilterOptions.blockvisible
    console.log("calling model to subscribe",options)
    model.subscribeContent(options, callback)

  self.RsortFilters.blockvisible = 1

  self.setupReactiveContentSubscription = _.once( ->
    Deps.autorun ->
      console.log("subscribing to content")
      self.RsubscribeFilteredSortedContent( ->
        NProgress.done();
      )
      NProgress.start();
  )

  Template.contentgrid.rendered = _.once ->
    self.setupReactiveContentSubscription()
    container = $("#contentgridcontainer")
    tomMasonry.init(container)

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
          tomMasonry.ms.appended(appenddiv)
        else
          $("#msnry_"+before._id).before(appenddiv)
          tomMasonry.ms.addItems(appenddiv)
          tomMasonry.ms.reload()
          tomMasonry.debouncedRelayout()
      removed: (e) ->
        console.log("removed")
        tomMasonry.remove($("#msnry_"+e._id))
        tomMasonry.debouncedRelayout()
      movedTo: (doc, fromIndex, toIndex, before) ->
        console.log("moved", doc, fromIndex, toIndex, before)
        if (before == null)
          container.append($("#msnry_"+e._id))
          tomMasonry.debouncedRelayout(true)
        else
          $("#msnry_"+before._id).before($("#msnry_"+e._id))
          tomMasonry.debouncedRelayout(true)
      changed: (newDoc, oldDoc) ->
        console.log("changed",newDoc,oldDoc)
        content = Meteor.render( ->
          Template.contentitem(newDoc)
        )
        $("#"+newDoc._id).replaceWith(content)


  Template.contentgrid.featured = ->
    console.log("getting cover photo")
    c = model.getContent({query:{featured: true}}).fetch();
    console.log("got featured",c)
    c
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
        self.RsortFilters.blockvisible++
    else

      # console.log('target became invisible (below viewable arae)');
      target.data "visible", false  if target.data("visible")
  , 10)

  Meteor.startup ->
    $(window).scroll(showMoreVisible);

  Template.filterbar.rendered = _.once ->
    navStamper.init($("#msnrynav"), 120,
      onStamped: (el) ->
        el.addClass("attop")
        el.removeClass("floating")
        console.log("stamped")

      onUnstamped: (el) ->
        el.removeClass("attop")
        el.addClass("floating")
        console.log("unstamped")
    )

  return self
