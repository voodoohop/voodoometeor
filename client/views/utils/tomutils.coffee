@batchify = (nonbatchfunc, batchfunc, time) ->
  argumentqueue = []
  batchifiedfunc = (args...)  ->
    argumentqueue.push(args)
    #console.log("argq", argumentqueue)
    lengthbeforewait = argumentqueue.length
    _.delay( f =  ->
      if (argumentqueue.length <= lengthbeforewait)
        processargs = argumentqueue
        argumentqueue = []
        if (processargs.length == 1)
          nonbatchfunc.apply(this, processargs[0])
        else
          #console.log("calling batched version", processargs)
          batchfunc.call(this, processargs,1)
    , time)

@isExternalLink = (url) -> RegExp('^((f|ht)tps?:)?//').test(url);

@eachWithDelay = (coll, delay, itemcallback, finishedcallback = null) ->
  c = _.clone(coll)
  processItem = ->
    current = c.shift()
    itemcallback(current)
    if (c.length > 0)
      _.delay(processItem, delay)
    else
      finishedcallback() if finishedcallback?
  processItem()


@eachWithDelayPerN = (coll, delay, n, itemcallback, finishedcallback = null) ->
  c = _.clone(coll)
  processItem = ->
    for blockno in [1..n]
      if c.length == 0
        finishedcallback() if finishedcallback?
        return
      current = c.shift()
      itemcallback(current)
    if (c.length > 0)
      _.delay(processItem, delay)
    else
      finishedcallback() if finishedcallback?
  processItem()



Meteor.startup ->
  Meteor.RwindowSize = new ReactiveObject(["width","height"])
  $(window).resize (  updateRwindowSize = _.debounce( ->
    Meteor.RwindowSize.width = $(window).width()
    Meteor.RwindowSize.height = $(window).height()
  , 100))
  updateRwindowSize()
  $(window).scroll( _.debounce(->
    $(".detach-on-scroll").each ->
      #console.log($(this).offset())
      if ($(this).offset().top  < $(window).scrollTop())
        $(this).find(".detach-content").addClass("detached animated slideInDown")
      else
        $(this).find(".detach-content").removeClass("detached animated slideInDown")

  , 100))