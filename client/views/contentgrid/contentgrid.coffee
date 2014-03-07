define "ContentgridController", ["VoodoocontentModel","Config","PackeryMeteor","ContentCommon","TomMasonry","NavBar", "NavStamper"], (model,config,packery,contentCommon, tomMasonry,navBar, navStamper) ->

  console.log("loading content grid")
  self = {}

  self.RsortFilters = new ReactiveObject(["filter","blockvisible", "path"])

  self.RsortFilters.blockvisible = 1

  self.RselectedItem = new ReactiveObject(["id","showingDetail","playingMedia", "itemWithDetails"])

  self.selectedItem = -> self.RselectedItem

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

  Template.contentitem.rendered = ->
    console.log("rendered content item", this)

  Template.contentgrid.voodoocontent = ->
    model.getContent({query: {}})
  Template.contentgrid.rendered = _.once ->
    console.log("rendered content grid")

    container = $("#contentgridcontainer")
    tomMasonry.init(container)

    console.log("setting up default content path")
    self.RsortFilters.filter = contentCommon.constructFilters(contentCommon.initpath)
    self.RsortFilters.path = contentCommon.initpath;

    console.log("rendering nav bar");

    navBar.initNavbar(container, self.RsortFilters)


    self.setupReactiveContentSubscription()

    # masonrify contenitem collection changes

    ###
    model.getContent({query: {}}).observe
      addedAt: (e, index, before) ->
        console.log("added", e, index, before)
        content = UI.render(Template.contentitemgridsizer.withData(e))
        if (before == null)
          UI.insert(content,container[0])
          #container.append(appenddiv)
          #tomMasonry.appended(content)
        else
          UI.insert(content, container[0], $("#msnry_"+before._id)[0])
          $("#msnry_"+before._id).before(appenddiv)
          tomMasonry.addItems(appenddiv)
          #tomMasonry.ms.reload()
        tomMasonry.debouncedRelayout(true)
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
      changed: (newDoc, oldDoc, atIndex) ->
        console.log("changed",newDoc,oldDoc)
        content = UI.render(Template.contentitemgridsizer.withData(newDoc))
        UI.insert(content, container[0], container.children("#msnry_"+oldDoc._id)[0])
        container.children("#msnry_"+oldDoc._id).eq(1).remove()
        # $("#"+newDoc._id).replaceWith(content)
        tomMasonry.debouncedRelayout(true)
    ###

  #Template.contentgrid.featured = ->
  #  console.log("getting cover photo")
  #  c = model.getContent({query:{featured: true}}).fetch();
  #  console.log("got featured",c)
  #  c
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

  self.isExpanded = (item) -> (self.RselectedItem.id == item._id) or item.expanded
  self.isShowDetail = (item) -> self.RselectedItem.id ==item._id and self.RselectedItem.showingDetail
  self.isPlayingMedia = (item) -> (self.RselectedItem.id == item._id) and self.RselectedItem.playingMedia

  self.playMedia =  (item) ->
    self.RselectedItem.id = item._id
    self.RselectedItem.showMedia = true

  Template.contentitemgridsizer.helpers contentCommon.helpers
  Template.contentitemgridsizer.isExpanded = -> self.isExpanded(this)
  Template.contentitemgridsizer.showDetail = -> self.isShowDetail(this)


  self.expandItem = (item) ->
    if (self.RselectedItem.id?)
      previousdata = model.contentCollection.findOne(self.RselectedItem.id)
      previousdata.justShrinked = true
    #console.log("expanding item, previous:",item, previousdata)
    if (self.RselectedItem.id == item._id)
      self.RselectedItem.id = null
      self.RselectedItem.showMedia = false
      self.RselectedItem.showingDetail = false
      item.justShrinked = true;
    else
      self.RselectedItem.id = item._id
      self.RselectedItem.showMedia = false
      self.RselectedItem.showingDetail = true
    console.log("set up reactive variables to expand item",self.RselectedItem)
  #Template.contentitemgridsizer.destroyed = ->
  #  console.log("removed from grid", this)

  Template.contentitemgridsizer.rendered = ->
    console.log("dataChanged")
    data = this
    tomMasonry?.appended($("#msnry_"+data._id)[0])
    if data.renderedcount?
      data.renderedcount++
    else
      data.renderedcount = 1
    console.log("rendered contentitemgridsizer ",data, data.renderedcount, data.justExpanded)
    if (data.justExpanded or data.justShrinked)
      console.log("just expanded or shrnked", data)
      Meteor.defer ->
        tomMasonry.ms?.on( 'layoutComplete',handler = ->
          tomMasonry.ms.off('layoutComplete', handler)
          $(window).scrollTo("#"+data._id,500,
            onAfter: -> self.listenForDetailLeavingWindow = true
          )
        )
      if (data.justExpanded)
        tomMasonry.ms.fit($("#msnry_"+data._id)[0])
      if (data.justShrinked)
        tomMasonry.ms.layout()
      data.justExpanded = undefined
      data.justShrinked = undefined

  Deps.autorun ->
    if (self.RselectedItem.showingDetail)
      console.log("subscribing to detail", self.RselectedItem.id)
      model.subscribeDetails(self.RselectedItem.id, ->
        self.RselectedItem.openDetailItem = model.getContentById(self.RselectedItem.id)
        console.log("open detail item:", self.RselectedItem.openDetailItem)
        self.RselectedItem.openDetailItem.justExpanded = true;
      )
    else
      self.RselectedItem.openDetailItem?.justShrinked = true;


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



  Router?.map ->
    this.route 'content',
      path:'/'
      template: 'contentgrid'
      layoutTemplate: 'mainlayout'
      #yieldTemplates:
      #  'filterbar': {to: 'navbar'}

  return self
