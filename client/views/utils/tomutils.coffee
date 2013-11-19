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