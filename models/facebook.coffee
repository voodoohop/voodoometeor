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
    # res = Meteor.sync((done) -> fb.api "/498352853588926/invited",{summary:true}, (fbres) -> done(null,fbres))

  #  fb.api "218099148337486",{fields: ["picture","cover"]}, (res) ->
  #    console.log(res)
    self.importUpdateEvent = (fbid) ->
      console.log("importing fb event with graph id:"+fbid)
      res = Meteor.sync((done) -> fb.api fbid, {fields: fbschemas.event_fields}, (fbres) -> done(null,fbres))
      event = res.result
      if event.end_time
        event.end_time = new Date(event.end_time).toJSON()
      voodoocontent =
        title: event.name
        location: event.location
        address: event.venue
        sourceId: event.id
        source: "facebook"
        facebookData: event
        picture: event.cover?.source
        start_time: new Date(event.start_time).toJSON()
        post_date: new Date(event.start_time).toJSON()
        end_time: event.end_time
        description: event.description
        type: "event"

      if (contentModel.getContentBySourceId(event.id).count() == 0)
        console.log("event: #{voodoocontent.title} not found yet... inserting")
        contentModel.contentCollection.insert voodoocontent
      else
        console.log("event: #{voodoocontent.title} found... updating")
        contentModel.contentCollection.update {sourceId: event.id}, {$set: voodoocontent}

      return voodoocontent

    self.importUpdatePost = (fbid) ->
          res = Meteor.sync ((done) -> fb.api fbid, {fields: fbschemas.post_fields}, (fbres) -> done(null, fbres) )
          post = res.result

          if (! post?.link?)
            console.log("without link... skipping")
            return;
          if (post.link.indexOf("facebook.com/events/") != -1)
            eventid = post.link.split("facebook.com/events/")[1].split("/")[0]
            console.log("found event... importing and ignoring post")
            return self.importUpdateEvent(eventid)

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
