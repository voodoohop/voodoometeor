require ["Config", "VoodoocontentModel","FBSchemas"], (config,contentModel, fbschemas) ->
  self = this

  if Meteor.isServer



    Meteor.startup ->
      Accounts.loginServiceConfiguration.remove
        service: "facebook"


      Accounts.loginServiceConfiguration.insert
        service: "facebook",
        appId: config.current().facebook.appid,
        secret: config.current().facebook.appsecret



    fb = Meteor.require "fb"
    console.log(config.current())

    fb.setAccessToken(config.current().facebook.pageaccesstoken)

  #  fb.api "218099148337486",{fields: ["picture","cover"]}, (res) ->
  #    console.log(res)
    self.importUpdateEvent = (fbid) ->
      console.log("importing fb event with graph id:"+fbid)
      res = Meteor.sync((done) -> fb.api fbid, (fbres) -> done(null,fbres))
      console.log(res)

      return res.result

    self.importUpdatePost = (fbid) ->
          res = Meteor.sync ((done) -> fb.api fbid, {fields: fbschemas.post_fields}, (fbres) -> done(null, fbres) )
          post = res.result
          #console.log(post)




          if (post.likes?)
            post.like_count = Meteor.sync((done) -> fb.api ""+post.id+"/likes",{summary:true}, (fbres) -> done(null, fbres) ).result.summary.total_count

           # has object_id if pointing to another image or video (can get high res thumb)
          if (post.object_id?)
            post.full_picture = Meteor.sync((done) -> fb.api post.object_id, (fbres) -> done(null, fbres) ).result.source
          else
            if (post.full_picture and post.full_picture.indexOf("url=") != -1)
              qs = {}
              for pair in post.full_picture.split("?")[1].split "&"
                [k, v] = pair.split("=")
                qs[k] = v
              if (qs["url"])
                post.full_picture = decodeURIComponent(qs["url"])


          voodoocontent =
            title: (post.name ? post.story) ? post.message
            link: post.link
            sourceId: post.id
            source: "facebook"
            facebookData: post
            picture: post.full_picture
            type: post.type
            post_date: new Date(post.created_time).toJSON()

          if (contentModel.getContentBySourceId(post.id).count() == 0)
            console.log("post: #{voodoocontent.title} not found yet... inserting")
            contentModel.contentCollection.insert voodoocontent
          else
            console.log("post: #{voodoocontent.title} found... updating")
            contentModel.contentCollection.update {sourceId: post.id}, {$set: voodoocontent}
          return voodoocontent

    Meteor.methods
      importFacebookEvent: self.importUpdateEvent
      importFacebookPost: self.importUpdatePost

    #return this #hack to not load posts

    #contentModel.contentCollection.remove({})

    pages= ["voodoohop", "ideafixa", "calefacaotropicaos"]
    Meteor.setTimeout( ->
     for page in pages

      res = Meteor.sync ((done) -> fb.api "/"+page+"/posts", {limit:30}, (fbres) -> done(null, fbres) )

      _.each( res.result.data, (post) ->

        self.importUpdatePost(post.id)
      )
    ,500)

    # facebook realtime notifications
    Meteor.Router.add '/fbrealtime', (params) ->
      console.log(params);




  return this
