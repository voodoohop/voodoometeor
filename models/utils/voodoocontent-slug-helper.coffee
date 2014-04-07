require ["VoodoocontentModel"], (model) ->
 Meteor.startup ->
  if Meteor.isServer
    generateSlug = (title) ->
      slug = Meteor.slugify(title)
      deDuplicatorString = ""
      deDuplicatorCounter = 0
      if (slug.length<3)
        slug = "content_"+slug
      while model.contentCollection.findOne({slug: slug+deDuplicatorString})
        deDuplicatorCounter++
        deDuplicatorString = ""+deDuplicatorCounter
      return slug+deDuplicatorString

    _.each(model.contentCollection.find({slug: {$exists: false}}).fetch(), (doc) ->
      slug = generateSlug(doc.title)
      model.contentCollection.update(doc._id, {$set: {slug: slug}})
      console.log("added slug", slug, " to doc:", doc._id)
    )

    model.contentCollection.before.insert (uid, doc) ->
      doc.slug = generateSlug(doc.title)
      doc._id = doc.slug