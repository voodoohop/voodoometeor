require ["Config", "VoodoocontentModel"], (config,contentModel) ->
  fb = Meteor.require "fb"
  console.log(config.current())

  fb.setAccessToken(config.current().facebook.pageaccesstoken)

#  fb.api "218099148337486",{fields: ["picture","cover"]}, (res) ->
#    console.log(res)

  #return #hack to not load posts

  contentModel.contentCollection.remove({})

  pages= ["voodoohop","ideafixa","calefacaotropicaos"]

  for page in pages

    res = Meteor.sync ((done) -> fb.api "/"+page+"/posts", {limit:50}, (fbres) -> done(null, fbres) )

    _.each( res.result.data, (post) ->
      #

      if (contentModel.getContentBySourceId(post.id).count() == 0)
        console.log("found POST:"+post.name)
        console.log("content not yet in db... inserting")

        # has object_id if pointing to another image or video (can get high res thumb)
        if (post.object_id?)
          post.source_picture = Meteor.sync((done) -> fb.api post.object_id, (fbres) -> done(null, fbres) ).result.source

        if (post.likes?)
          post.like_count = Meteor.sync((done) -> fb.api ""+post.id+"/likes",{summary:true}, (fbres) -> done(null, fbres) ).result.summary.total_count

        contentModel.contentCollection.insert
          title: (post.name ? post.story) ? post.message
          link: post.link
          sourceId: post.id
          source: "facebook"
          facebookData: post
          picture: post.source_picture
          type: post.type
        if (post.link)
          console.log("post has link:"+post.link)

        console.log(post.link)
        console.log(post.picture)
    )


  # facebook realtime notifications
  Meteor.Router.add '/fbrealtime', (params) ->
    console.log(params);
