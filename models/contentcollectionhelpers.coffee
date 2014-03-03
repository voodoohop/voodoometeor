define "ContentcollectionHelpers", ["VoodoocontentModel","FacebookApiAbstraction"], (model,fbApiAbstraction) ->
  createHelpers = (fb) -> _.map(fbApiAbstracion, (a, k) ->
      return null unless a.canExecute()
      return ->
        a.apiCall(this, fb)
    )



  model.contentCollection.before.insert (uid, doc) ->
    doc.likes = [] unless doc.likes

  console.log("registering content collection hooks")
  model.contentCollection.after.update (uid, doc, fields, modifier, options) ->
    console.log("content collection after update", uid, fields, modifier, options)
    if (_.contains(fields,"fbstats") or _.contains(fields,"likes"))
      console.log("likes changed")
      like_count = if doc.likes? then doc.likes.length else 0
      if doc.type == "event" and doc.fbstats?.voodooAttendingCount
        like_count += doc.fbstats.voodooAttendingCount
      model.contentCollection.update(doc._id, {$set: {inferred_likes: like_count }})


require ["ContentcollectionHelpers"], (collHelpers) ->