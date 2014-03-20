define "ContentgridController", ["VoodoocontentModel","Config","PackeryMeteor","ContentCommon","TomMasonry","NavBar", "NavStamper"], (model,config,packery,contentCommon, tomMasonry,navBar, navStamper) ->

  console.log("loading content grid")
  self = {}


  self.RsortFilters = new ReactiveObject(["blockvisible"])

  self.RsortFilters.blockvisible = 1

  self.RselectedItem = new ReactiveObject(["id","showingDetail","playingMedia", "itemWithDetails"])

  self.selectedItem = -> self.RselectedItem

  self.subscribeFilteredSortedContent = (sortFilterOptions, callback)  ->
    console.log("subscribing",sortFilterOptions)

    options =
      query: sortFilterOptions.filter.query
      sort: sortFilterOptions.filter.sortFilter
      blockno: sortFilterOptions.blockvisible
    console.log("calling model to subscribe",options)
    return Deps.nonreactive ->
      model.subscribeContent(options, callback)



  Template.contentgrid.rendered = ->
    console.log("rendered content grid")


  Template.contentgrid.moreResults = ->
    model.lastItemCount() >= model.lastLimit;

  showMoreVisible = _.debounce( ->
    threshold = undefined
    target = $("#showMoreResults")
    return unless target.length
    threshold = $(window).scrollTop() + $(window).height() - target.height()+100
    console.log(threshold, target.offset().top)
    if target.offset().top < threshold
      unless target.data("visible")
        console.log('target became visible (inside viewable area)');
        target.data "visible", true
        self.RsortFilters.blockvisible++
    else


      target.data "visible", false  if target.data("visible")
  , 50)

  Meteor.startup ->
    $(window).scroll(showMoreVisible);

  self.isPlayingMedia = (item) -> (self.RselectedItem.id == item._id) and self.RselectedItem.playingMedia

  self.playMedia =  (item) ->
    self.RselectedItem.id = item._id
    self.RselectedItem.showMedia = true

  Template.contentitemgridsizer.helpers contentCommon.helpers


  Template.contentgrid.dayDifferent = (item1, item2) ->
    diff = moment(item2?.start_time).dayOfYear() - moment(item1?.start_time).dayOfYear()
    console.log(diff)
    return diff != 0


  Router?.map ->
    this.route 'content',
      path:'/content/*'
      template: 'contentgrid'
      layoutTemplate: 'mainlayout'
      #yieldTemplates:
      #  'filterbar': {to: 'navbar'}
      waitOn:  ->
        Deps.currentComputation.onInvalidate ->
          console.trace()

        console.log("contentgrid waitOn", this.params[0])
        path = this.params[0].split("/")
        console.log("path",path)
        self.RsortFilters.filter = contentCommon.constructFilters(path)
        self.RsortFilters.path = path
        self.subscribeFilteredSortedContent(self.RsortFilters)

      data: ->
        console.log("contentgrid data, filter:", self.RsortFilters.filter, this.ready())
        #if (!this.ready())
        #  console.log("not ready so no data")
        #  return null;
        dta = _.map(items = model.getContent({query: {}}).fetch(), (item,i) ->
            _.extend({previous: items[(i - 1)]}, item)
        )
        console.log("got data:", dta)
        dta
  navBar.initNavbar(null, self.RsortFilters)

  return self
