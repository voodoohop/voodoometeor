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

  console.log("setting up default content path")
  self.RsortFilters.filter = contentCommon.constructFilters(contentCommon.initpath)
  self.RsortFilters.path = contentCommon.initpath;

  Template.contentgrid.rendered = ->
    console.log("rendered content grid")

    container = $("#contentgridcontainer")








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

  Template.contentgrid.dayDifferent = (item1, item2) ->
    console.log("dayDifferent", item1, item2)

    diff = moment(item2?.start_time).dayOfYear() - moment(item1?.start_time).dayOfYear()
    console.log(diff)
    return diff != 0

  Template.contentitemgridsizer.destroyed =  ->
    tomMasonry?.debouncedRelayout(true)

  Template.contentitemgridsizer.rendered = ->
    console.log("contenitemgridsizer rendered",this)
    data = this.data

    console.log("rendered contentitemgridsizer ",data, data.justExpanded)
    if (data.justExpanded or data.justShrinked)
      console.log("just expanded or shrnked", data)
      Meteor.defer ->
        tomMasonry.ms.on( 'layoutComplete',handler = ->
          tomMasonry.ms.off('layoutComplete', handler)
          $(window).scrollTo("#"+data._id,500,
            onAfter: -> self.listenForDetailLeavingWindow = true
          )
        )
      if (data.justExpanded)
        tomMasonry.ms.fit($("#msnry_"+data._id)[0])
      if (data.justShrinked)
        tomMasonry.debouncedRelayout()
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
      before: ->
        self.setupReactiveContentSubscription()
      data: ->
        _.map(items = model.getContent({query: {}}).fetch(), (item,i) ->
            _.extend({previous: items[(i - 1)]}, item)
        )
  navBar.initNavbar(null, self.RsortFilters)

  return self
