define "ContentgridController", ["VoodoocontentModel","Config","PackeryMeteor","ContentCommon","ContentItem", "TomMasonry"], (model,config,packery,contentCommon, contentItem, tomMasonry) ->

  console.log("loading content grid")
  self = {}

  self.RsortFilters = new ReactiveObject(["content_sort","active_content_filters","blockvisible"])

  self.RsortFilters.blockvisible = 1

  self.subscribeFilteredSortedContent = (callback)  ->
    content_sort = self.RsortFilters.content_sort
    console.log("subs content_sort",content_sort)
    if content_sort?
      sort = {}
      sort[content_sort.name] = content_sort.order
    orfilters =  []
    console.log("active_c_filters",self.RsortFilters.active_content_filters)
    _.each self.RsortFilters.active_content_filters, (f) ->
      #console.log("adding filter:",f)
      orfilters.push({type: f})
    #filters.post_date = { "$gte": (new Date()).toISOString() }
    #filters["address.city"] = "São Paulo"
    #filters["type"] = "video"
    #filters["num_app_users_attending"] = {"$gte": 1}

    options =
      query: if orfilters.length > 0 then {$or: orfilters} else {}
      sort: sort
      blockno: self.RsortFilters.blockvisible
    console.log("calling model to subscribe",options)
    model.subscribeContent(options, callback)

  self.RsortFilters.blockvisible = 1

  self.setupReactiveContentSubscription = _.once( ->
    Deps.autorun ->
      console.log("subscribing to content")
      self.subscribeFilteredSortedContent( ->
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

  return self
