#TODO
#reset blockno when changing routes

define "ContentgridController", ["VoodoocontentModel","Config","ContentCommon","TomMasonry","NavBar","LoadingTemplates"], (model,config, contentCommon, tomMasonry,navBar, loadingTemplates) ->

  console.log("loading content grid")



  self = {}

  updateHeadData =  ->
    SEO.set
      title: "VOODOOHOP - " + contentCommon.getTitleFromPath(self.RsortFilters.path)
      meta:
        description: "MUSIC - ART - CULTURE - HEDONISM"
      og:
        title: "VOODOOHOP - " + contentCommon.getTitleFromPath(self.RsortFilters.path)
        description: "MUSIC - ART - CULTURE - HEDONISM"
        image: Meteor.absoluteUrl("images/voodoologo_site_nav.png")
        type: "website"
        url: Meteor.absoluteUrl(window.location.pathname.slice(1))
        site_name: "VOODOOHOP"
      fb:
        app_id: "78013154582"

  self.RsortFilters = new ReactiveObject(["blockvisible"])

  self.RsortFilters.blockvisible = 1



  self.contentParams = (withblock=true) ->
    sortFilterOptions = self.RsortFilters
    res =
      query: sortFilterOptions.filter.query
      sort: sortFilterOptions.filter.sortFilter
      blockno: sortFilterOptions.blockvisible if withblock

  self.subscribeFilteredSortedContent = (callback)  ->
    #console.log("subscribing",self.RsortFilters)
    options = self.contentParams()
    #console.log("calling model to subscribe",options)
    return Deps.nonreactive ->
      model.subscribeContent(options, callback)



  Template.contentgrid.rendered = ->
    console.log("rendered content grid")
    updateHeadData()

  Template.contentgrid.moreResults = ->
    model.lastItemCount() >= model.lastLimit;

  showMoreVisible = _.debounce( ->
    threshold = undefined
    target = $("#showMoreResults")
    return unless target.length
    threshold = $(window).scrollTop() + $(window).height() - target.height()+100
    #console.log(threshold, target.offset().top)
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

  Template.contentgrid.dayDifferent = (item1, item2) ->
    diff = moment.parseZone(item2?.start_time).local().dayOfYear() - moment.parseZone(item1?.start_time).local().dayOfYear()
    #console.log(diff)
    return diff != 0
  Template.contentgrid.filter = ->
    Session.get("currentParams")[0]?.split("/")[0]
  Template.contentgrid.isWall = ->
    Session.get("currentParams")[0]?.split("/")[0] == "wall"

  Router?.map ->
    this.route 'content',
      path:'/content/*'
      template: 'contentgrid'
      layoutTemplate: 'mainlayout'
      #yieldTemplates:
      #  'filterbar': {to: 'navbar'}
      waitOn:  ->
        console.log("contentgrid waitOn", this.params[0])
        path = this.params[0].split("/")
        console.log("path",path)
        self.RsortFilters.filter = contentCommon.constructFilters(path)
        self.RsortFilters.path = path
        self.RsortFilters.category = _.findWhere(contentCommon.filterOptions, {name: path[0]})
        console.log("selected category", self.RsortFilters.category)
        #loadingTemplates.loadingContent()
        self.subscribeFilteredSortedContent()
      action: ->
        if this.ready()
          this.render()
          self.loading = false
        else
          unless self.loading
            self.loading = true
            loadingTemplates.renderRandom(this)
      data: ->
        category = self.RsortFilters.category
        #if (!this.ready())
        #  console.log("content data not ready returning null")
        #  return null;
        console.log("contentgrid data, filter:", self.RsortFilters.filter, this.ready())
        #if (!this.ready())
        #  console.log("not ready so no data")
        #  return null;
        console.log(self.contentParams(false))
        gridContent = _.map(items = model.getContent(self.contentParams(false)).fetch(), (item,i) ->
            _.extend({previous: items[(i - 1)]}, item)
        )
        #console.log("got grid content from iron router data", gridContent, self.contentParams(false))
        #gridContent = model.getContent(self.contentParams(false)).fetch()
        featuredContent = model.getContent({query:{featured: true}}).fetch()
        {gridContent: gridContent, featuredContent: featuredContent, category, isChild: false}
      onStop: ->
        Router.lastGridPath = this.path
        self.RsortFilters.blockvisible=1
      fastRender:true
  navBar.initNavbar(null, self.RsortFilters)

  return self
