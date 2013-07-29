require ["Config", "VoodoocontentModel"], (config,contentModel) ->
  fb = Meteor.require "fb"
  console.log(config.current())

  fb.setAccessToken(config.current().facebook.pageaccesstoken)

#  fb.api "218099148337486",{fields: ["picture","cover"]}, (res) ->
#    console.log(res)

  res = Meteor.sync ((done) -> fb.api "/me/posts", {limit:25}, (fbres) -> done(null, fbres) )

  _.each( res.result.data, (post) ->
    console.log("found POST:"+post.name)

    if (contentModel.getContentBySourceId(post.id).count() == 0)
      console.log("content not yet in db... inserting")
      contentModel.contentCollection.insert
        title: post.name
        link: post.link
        sourceId: post.id
        source: "facebook"
        facebookData: post
    if (post.link)
      console.log("post has link:"+post.link)

    console.log(post.link)
    console.log(post.picture)
  )


  # facebook realtime notifications
  Meteor.Router.add '/fbrealtime', (params) ->
    console.log(params);
