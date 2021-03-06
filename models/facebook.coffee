#TODO event hooks is causinga  performnace hit. find another way to catch onLoggedIn and do the swap for a long-lived access token

require ["Config", "VoodoocontentModel","FBSchemas"], (config,contentModel, fbschemas) ->
  self = {}
  # Meteor.users.remove({})
  if Meteor.isServer

    fbApi = (path,options, callback) ->
      fb.api(path, options, callback)
    fbSync = Meteor._wrapAsync(fbApi)

    Hooks?.onLoggedIn = (p) ->

        ## exchange access token for long-lived ##
        return unless p?

        user = Meteor.users.findOne(p)
        return unless user.services?.tomfacebook
        console.log("onloggedin",user, p)
        return if user.services.tomfacebook.extendedAccessToken
        console.log("exchanging access token to extended for user", p)
        currentToken = user.services.tomfacebook.accessToken
        console.log("loggedin, getting extended access token",p)
        fb.api("/oauth/access_token",
          client_id: config.current().facebook.appid,
          client_secret: config.current().facebook.appsecret
          grant_type: 'fb_exchange_token'
          fb_exchange_token: currentToken
        , Meteor.bindEnvironment((res) ->
          if (res.access_token?)
            Meteor.users.update(p,
              $set:
                "services.tomfacebook.accessToken": res.access_token
                "services.tomfacebook.extendedAccessToken": true
            )
            console.log("updated extended access token")
        , (ex) ->
          console.log("bind failed",ex)
        ))

    ignoredFBEvents = new Meteor.Collection("ignoredFBEvents")


    @fb = Meteor.require "fb"
    console.log(config.current())

    fb.setAccessToken(""+config.current().facebook.appid+"|"+config.current().facebook.appsecret)

    #fb.api("/"+config.current().facebook.appid+"/subscriptions", (res) -> console.log(res))

    fb.setAccessToken(config.current().facebook.pageaccesstoken)

    #fb.api("/fql",{q:"SELECT message,actor_id FROM stream WHERE source_id ='234353413437639'"}, (fbres) -> console.log("EVENT STREAM RES,",fbres))
    #fb.api("/234353413437639/feed", (fbres) -> console.log("EVENT STREAM RES2",fbres))

    #fb.api("/voodoohop", (res) -> console.log("pagetest",res))
    # res = Meteor.sync((done) -> fb.api "/498352853588926/invited",{summary:true}, (fbres) -> done(null,fbres))

    #  fb.api "218099148337486",{fields: ["picture","cover"]}, (res) ->
    #    console.log(res)
    self.importUpdateEvent = (fbid, update=false) ->
      return unless fbid
      console.log("update",update)
      console.log("importing fb event with graph id:"+fbid)
      ignoredEvent = ignoredFBEvents.findOne({_id: fbid})
      if (ignoredEvent and moment().diff(ignoredEvent.updated_time)/1000 < 60*60*4)
        console.log("diff for ignored event", moment().diff(ignoredEvent.updated_time)/1000)
        return {error: "toofewappusers", fbEventId: fbid}
      existing = contentModel.getContentBySourceId(fbid)
      if (existing)
        if (!existing.updated_time)
          update = true
        else
         if moment().diff(moment(existing.updated_time))/1000 > 600
            update = true
      if (!update and existing)
        console.log("event already exists")
        return {event: existing._id, alreadyInDB: true}
      res = Meteor.sync((done) ->
        query= "select uid from user where is_app_user=1 and uid in (select uid from event_member where eid = "+fbid+" and rsvp_status='attending')";
        fb.api("/fql",{q:query},  (fbres) -> done(null,fbres))
      )
      num_app_users_attending = res.result.data?.length ? 0
      if (num_app_users_attending < 3)
        if (ignoredEvent)
          ignoredFBEvents.update(fbid, {$set:{updated_time: moment().toJSON()}})
        else
          ignoredFBEvents.insert({_id:fbid, updated_time: moment().toJSON()})
        console.log("few app users attending, ignoring event")
        return {error: "toofewappusers", fbEventId: fbid}
      res = Meteor.sync((done) -> fb.api fbid, {fields: fbschemas.event_fields}, (fbres) -> done(null,fbres))
      console.log("fberr", res) unless res.result?.id
      event = res.result
      return {error: "eventnotloadedfromfb", fbEventId: fbid, fbErr: res} unless event?.id

      res = Meteor.sync((done) -> fb.api ""+fbid+"/attending",{summary:true}, (fbres) -> done(null,fbres))
      numattending = res.result.summary.count

      start_time = if event.start_time.length == 10 then moment.utc(event.start_time).hour(12).toJSON() else moment.parseZone(event.start_time).toJSON()
      voodoocontent =
        title: event.name
        location: event.location
        address: event.venue
        sourceId: event.id
        source: "facebook"
        facebookData: event
        picture: event.cover?.source ? event.picture?.data?.url
        start_time: start_time
        only_date: event.start_time.length == 10
        post_date: start_time
        end_time: if event.end_time? then moment.parseZone(event.end_time).toJSON() else undefined
        description: event.description
        type: "event"
        like_count: numattending
        num_attending: numattending
        num_app_users_attending: num_app_users_attending
        updated_time: moment().toJSON()

      if (!contentModel.getContentBySourceId(event.id))
        console.log("event: #{voodoocontent.title} not found yet... inserting")
        contentModel.contentCollection.insert voodoocontent
      else
        console.log("event: #{voodoocontent.title} found... updating")
        contentModel.contentCollection.update {sourceId: event.id}, {$set: voodoocontent}
      return {event: contentModel.getContentBySourceId(fbid)._id, alreadyInDB: false, updated: update}

    self.importUpdatePost = (fbid, additionalFields = {}) ->
          res = Meteor.sync ((done) -> fb.api fbid, {fields: fbschemas.post_fields}, (fbres) -> done(null, fbres) )
          post = res.result
          #console.log("post,",post)

          if (! post?.link?)
            console.log("without link... skipping")
            return;
          if (post.link.indexOf("facebook.com/events/") != -1)
            eventid = post.link.split("facebook.com/events/")[1].split("/")[0]
            console.log("found event... importing and ignoring post")
            return self.importUpdateEvent(eventid)

          if (post.likes?)
            post.like_count = Meteor.sync((done) -> fb.api ""+post.id+"/likes",{summary:true}, (fbres) -> done(null, fbres) ).result.summary.total_count

            res = Meteor.sync((done) ->

              whereclause =  if post.object_id? then " object_id='" + post.object_id + "' " else " post_id='"+post.id+"'"
              query= "select uid from user where is_app_user=1 and uid in (select user_id from like where "+whereclause+")";
              console.log(query)
              fb.api("/fql",{q:query},  (fbres) -> done(null,fbres))
            )
            console.log(res)
            post.num_app_user_likes = res.result.data.length

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
            like_count: post.like_count
            post_date: new Date(post.created_time).toJSON()
            num_app_users_attending: post.num_app_user_likes

          _.extend(voodoocontent, additionalFields)

          if (!contentModel.getContentBySourceId(post.id))
            console.log("post: #{voodoocontent.title} not found yet... inserting")
            contentModel.contentCollection.insert voodoocontent
          else
            console.log("post: #{voodoocontent.title} found... updating")
            contentModel.contentCollection.update {sourceId: post.id}, {$set: voodoocontent}
          return contentModel.getContentBySourceId(post.id)._id

    self.numEventsImporting=0;
    Meteor.methods(
      importFacebookEvent: (params) ->
        #return false
        self.numEventsImporting++;

        this.unblock() #if self.numEventsImporting < 10
        console.log("calling update", params)
        result = self.importUpdateEvent(params)
        self.numEventsImporting--;

        return result;

      importFacebookPost: (params, additionalFields={}) ->
        this.unblock()
        self.importUpdatePost(params, additionalFields)

    )

    #Meteor.setTimeout( ->
    #  _.each([("a".charCodeAt(0))..("z".charCodeAt(0))], (l) ->
    #    console.log("searching and inserting events with letter",l)
    #    res = Meteor.sync ((done) -> fb.api "/search", {limit:5000,since: moment().unix(),locale:"pt_BR",q:String.fromCharCode(l),type:"event"}, (fbres) -> done(null, fbres) )
    #    _.each( res.result.data, (post) ->
    #      self.importUpdateEvent(post.id)
    #
    #    )
    #  )
    #,500)
    #console.log("fbsynctest",fbSync("/voodoohop"))
    #contentModel.contentCollection.remove({})
    return self #hack to not load posts
    console.log("importing page posts")
    pages= ["FreeFolk","voodoohop", "ideafixa", "calefacaotropicaos", "209127459210998", "CatracaLivre","ateliecompartilhado","240801296089491"]
    Meteor.setTimeout( ->
     for page in pages
      res = Meteor.sync ((done) -> fb.api "/"+page+"/posts", {limit:20}, (fbres) -> done(null, fbres) )
      _.each( res.result.data, (post) ->

        self.importUpdatePost(post.id)
      )
    ,500)

    # facebook realtime notifications
    return self

    #update existing events
    Meteor.setTimeout( ->
      events = contentModel.getContent({query: {type: "event", post_date: { "$gte": (new Date()).toISOString() }}}).fetch()
      lists = _.groupBy(events, (a,b) -> Math.floor(b/10))
      _.each(lists, (l) ->
        Meteor.setTimeout( ->
          _.each(l, (e) -> self.importUpdateEvent(e.sourceId, true))
        , 500)
      )
    , 500)


  return self



  fbevents = ["100926449983092", "137571779639007", "109468209131428", "192730507418490", "196957800333139", "167714146610136", "203956899614558", "192248324128833", "207854555892709", "176642959155740", "446260292115320", "483719601690559", "379745852138918", "179546332195363", "191723184183461", "101232636626097", "184599051582978", "197313356969084", "192003370838121", "103128749770801", "201191909911948", "126589344083950", "166105583443498", "162685593784774", "215235615160164", "209929705702169", "114530438629619", "194069033970341", "166710450059241", "122457864505030", "192476857449793", "222624887755082", "170935989627510", "218857518140343", "184471101604577", "108404475913780", "119229934823657", "114102475341041", "186366874746953", "211591692207366", "171357432920940", "199885993389815", "192255574155221", "226957797329722", "189234067793217", "224421207587346", "178913308830902", "226687350690096", "174382875959075", "143323742410876", "183140158410340", "225497647481349", "219249238111104", "253295604683638", "174675455932475", "194884460570101", "255662571111219", "235674016455023", "195379197185633", "190740280982219", "226504147381571", "243306692358500", "200043466715533", "192430184150108", "142055899211183", "146660402083867", "238865092813500", "156484267767231", "247712905260172", "221487667908079", "197207873676564", "240430682667691", "226360950749980", "279817198699124", "138787366213900", "204512739612345", "142307702529908", "157257887692614", "279425678734726", "144554055637398", "263395520347702", "274452942582039", "171173432961469", "253683574666795", "287393384605127", "141543692610440", "177993412276105", "286773944665965", "265684043460804", "248533285190228", "283304665029435", "138139372952013", "161894703896775", "169007846518542", "159543380804166", "133522493415866", "125628494206939", "185742574837079", "213257932073280", "112368155541794", "269806686397826", "304433122915848", "268473339852531", "203893006346965", "274107205956902", "188482127894351", "190696027674018", "217728268294269", "119639768144754", "116109711831697", "311579398857071", "129782037130041", "101441859970978", "190152647730363", "240240692696128", "239477399442621", "214459985293068", "260149544035246", "317624758248061", "306334389386144", "199370646806141", "115596561888786", "238314906232181", "279469962094778", "286305144724079", "250390171676561", "238625549532334", "284085651624178", "316623111697817", "282618365090339", "296194957067973", "191888194219122", "284273334946184", "275662149141950", "234017616663648", "295155497173615", "332821953401922", "283671068340682", "121542664625836", "289925581048160", "164241283673731", "304859736211828", "106691932781336", "250488448349388", "263040013753506", "282693478442964", "135855846525372", "323958200965159", "328475230515296", "308084259225604", "299620300071104", "217395275002721", "192284370859135", "129426377171218", "305453046156357", "306560486033632", "203345203084929", "239011032834186", "302466983109420", "214146955330517", "257741560954783", "124400694342648", "222792271131224", "123877371064708", "232834916791140", "167669046670383", "285125868205045", "315194381858241", "301340989912909", "352550428089024", "314111838631589", "279991378703350", "330918490281601", "153177084789595", "361529290525695", "292535014137176", "260335077373222", "159239600855497", "240964169316515", "368420763184823", "202800876485764", "329863660370301", "234988789919220", "301083456607276", "315232301845890", "349367381767877", "320641937971850", "153172854800990", "109243222534123", "326668177376703", "327897857242198", "188901304557853", "324710730904024", "113629925428220", "111233305667373", "268939063176200", "110280379099542", "359416314080505", "https://www.facebook.com/events/351376191568638/", "351376191568638351376191568638/ ", "351376191568638", "384313044930832", "238243136267999", "241027999322421", "400402819976377", "120295724762218", "372997109384890", "308630839199768", "267755689968404", "239863296107750", "273746702718543", "360372250668701", "222862261144512", "168365746613142", "287474011322817", "318180661570879", "322593917790119", "151846558268893", "381423865214763", "392639650746771", "174552475988618", "288836187852761", "276654645742731", "335753259805699", "173394529432381", "154486157990233", "408478432499126", "100309903436213", "304515352952359", "267824056632880", "347205125322178", "197797650323530", "378860872145620", "366115133407051", "343286682396469", "202773906504061", "203696089743796", "151841071608818", "343952088995303", "402013203151499", "206860216094969", "276878199063561", "342108905845429", "359603004097086", "125955150861474", "245128912251116", "362457777133758", "338893362830623", "433115840047950", "391898994183737", "226615057444490", "417995461544813", "152725598186857", "340755139324731", "188609677925710", "306901182719313", "449262538421833", "207499429361709", "418074831545797", "299549840127547", "448741238486092", "296439127098261", "171366896322890", "121744314628422", "285433078214364", "236411236465032", "396012747125390", "226974474072007", "367829656597894", "217333038291502", "439820146048084", "272010672897823", "338128332927254", "311495552266122", "435621006463063", "376422595743196", "416409285049313", "394247367284972", "392252827485806", "332038910198517", "348315315223504", "370570542998982", "101852596621230", "460194703994554", "168785286583229", "436113023073562", "315464875197461", "200047773451590", "326603260750881", "395242240513359", "309642265790331", "237623449684460", "158861444247772", "317327318351822", "390463904332880", "407714615947157", "167578706708304", "451005614917928", "149552988502394", "372784736108269", "227802140673222", "462047687138693", "415859535123173", "507092355982857", "408068955906670", "257864867655473", "244638638989103", "http://www.facebook.com/events/119501681522815/", "119501681522815", "413064235406404", "321777927903440", "480804368613587", "457174937634262", "405524266150693", "446791275361043", "284021331705566", "447405888627349", "170635886394988", "342807285799842", "181912698608047", "127835710692073", "395510737195463", "363999767002558", "133042080169203", "224265937696542", "402143353176952", "477469058931113", "173453896120386", "503329003026057", "461568103863148", "180274598769678", "271243052984842", "390764257657686", "401727733220922", "184555075010378", "334058646684532", "486787711332238", "142528219220624", "436273743083171", "402843669776695", "430830186967369", "375735149164541", "256011834517200", "424331274269190", "261519547299682", "379101755493339", "145413398933280", "483591968336279", "109038462579524", "403995619668072", "269841459797139", "418484818215600", "278278492274377", "149242128546835", "194952867303618", "422403291142622", "269964439790173", "531512656875452", "418220194901104", "422946484420096", "401860489869731", "465303250168859", "186792691455772", "179431972192251", "378228218915090", "478082028890825", "282376895199642", "407761585944113", "522659191081274", "381836928552194", "531373060209410", "528348610512729", "273301772787832", "492488327436515", "422724751118079", "504405259588953", "351369831624382", "335342609894516", "303625639744965", "534687153214522", "435645296470984", "510093832334902", "111104652378970", "435375149831609", "123849717763432", "380937225308791", "296854380423259", "233565863436050", "358590694222224", "536962696319443", "117694231718035", "315814781859143", "433169650073617", "320893608008318", "217706021693643", "272270789562832", "124582994358588", "513802921981964", "340300772733007", "403317946408707", "115793658578492", "106199119541585", "159075517569446", "287926267986003", "238200699641576", "459117297462987", "508295089181657", "376834835732098", "321807844593833", "484080738298267", "396493537086947", "453499294693045", "420920844627728", "415446738509936", "377973018952136", "371779716237229", "134988826650110", "299173966854763", "106610669503311", "451152131588740", "365729110184719", "360298354059758", "243416772450570", "488876764478223", "391267074275392", "163559283789217", "125765307580878", "362942460461649", "469178823123582", "428326180567194", "300081573424939", "422453147821181", "414965455228637", "177678249037138", "450531091661511", "376657909086192", "505701152794390", "296456143800082", "129431500546310", "459213437472510", "314925255282495", "469313073110006", "306172626161490", "390402034373297", "361203230640128", "389762284432625", "467674639944843", "378680315559908", "428736383847485", "322446427868193", "393564790737192", "392538240836941", "257270651068521", "147054698780583", "307579622696786", "191015761044485", "327119097398372", "182734291871438", "477381982305608", "318571088252184", "107904699336718", "156242451190911", "465630263496395", "328525477252498", "203134826496300", "324967977613125", "519418488097801", "478140745554919", "351511408289628", "319884361461716", "408974339183033", "232740353528849", "322146511230296", "522116447810614", "509647925740653", "522825947747836", "614859691862653", "153675181453985", "338423739601177", "485613518141178", "275259882605588", "604969689529836", "424406557644985", "339372886162798", "357079717739439", "174022632745385", "189635361160060", "441786572564457", "500004220038631", "161876627301128", "547564961954838", "128642880651674", "432984730119572", "134700006709757", "254512654686132", "114641585394364", "388925397872832", "325974330838912", "130170403833901", "393239650774076", "517806514939513", "169973663160208", "508186159218182", "100162446847182", "427564793999449", "291653940965046", "133654306821183", "159654944200258", "384772734970165", "353653141413129", "504519386261829", "271733582962428", "489526851101836", "404990812932495", "566140963418760", "101723143363084", "247502982056430", "377080675737909", "117430841788406", "609479085747484", "442189352541171", "318381188288915", "274385272698407", "190297387787989", "142405395946728", "192447787573056", "462234123858648", "246235625518952", "198183713662497", "139356312921120", "188286991321894", "497542593645131", "620476857982526", "522810511088060", "381729315271747", "458719317545591", "188282407994401", "526372784094212", "259091304232387", "574246739282470", "650535241628794", "574280835936124", "599568823394510", "579208048769263", "218099148337486", "301624373306450", "663115230380544", "631225993571823", "310051482462587", "461271263961483", "388686977904556", "517812461619734", "349494455153002", "675834129098924", "355549644571204", "306394852831346", "178912032283849", "539993532703298", "494486833953997", "141609029377245", "656607451033227", "590056401038402", "162581197263314", "147898175411153", "645608462128470", "321479414653820", "351552761638338", "335593936574348", "120858701418155", "590978917602748", "184992888342583", "578381468880660", "296273140516258", "369852346470730", "469528489810630", "278577115614576", "520968431310281", "557709800952492", "386548938134211", "313125798824663", "545003818870659", "538292222903501", "1394579077431022", "1392303730993051", "612589462095252", "210627705762486", "193223104184912", "498352853588926", "647807848565083", "453260724771374", "579470568758152", "371497496312125", "295212507287610", "1376972029200785", "1377820042447247", "541388295910564", "402024663231506", "522641357793415", "287830038026545", "156874181175746", "233959160091436", "188675087980235", "386990908093275", "203974733102445", "313114292159608", "166318496887238", "233187983500167", "156849027848649", "165381663663706", "1413906985496050", "1416879145191532", "215259551961898", "597517503645475", "123577267812476", "202792006559484", "649097351790174", "466601010114692", "169115886611702", "721031417911055", "150850795125865", "594022763995369", "637022329654654", "323521267789910", "736689646348264"]
  delay = 0
  _.each fbevents, (evt) ->
   Meteor.setTimeout( ->
    Meteor.call "importFacebookEvent", evt, (e, s) ->
      console.log e, s
   ,delay)
   delay += 200

  ## import all fb
  ## FB.api("/me/friends",{limit:3000}, function(res) { _.each(res.data, function (u) {FB.api(u.id+"/events/attending", function(e) {_.each(e.data,function(event) {Meteor.call("importFacebookEvent",event.id)})})}) })
