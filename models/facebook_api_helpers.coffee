#TODO
# get feed posts and users to populate comments FB.api("/fql",{q:{"query1": "SELECT actor_id, message FROM stream WHERE source_id ='234353413437639'",
# "query2":"SELECT uid, name FROM user WHERE uid IN (SELECT actor_id FROM #query1)", "query3":"SELECT page_id, name FROM page WHERE page_id IN (SELECT actor_id FROM #query1)"}}, function(res) {console.log(res)})

define "FacebookApiHelpers", [], ->

  class fbApiCaller
    run: (contentItem, fbapi, callback) ->
      @fbapi = fbapi.api.api
      self = this
      if @canExecute() and contentItem.type == @contentType
        @apiCall(contentItem, fbapi, (resData) ->
          console.log("got result from facebook api call", resData, "call updateDB?", self.updateDB?)
          if self.updateDB?
            self.updateDB(contentItem, resData, (res2) ->
              callback?(resData)
            )
          else
            callback?(resData)
        )

  return {
    appUsersAttendingEvent: new class extends fbApiCaller
        canExecute: ->
          Meteor.isServer or Meteor.isClient
        contentType: "event"
        apiCall: (content, fbapi, callback) ->
          query = "select uid from user where is_app_user=1 and uid in (select uid from event_member where eid = "+content.sourceId+" and rsvp_status='attending')"
          fbapi.api.api("/fql", {q: query}, (res) -> callback?(res.data))
        updateCollection: (contentCollection, itemId, apiResult) ->
          contentCollection.update(itemId, {$set: {stats: {numAppUsersAttending: apiResult.length}}})

    friendsAttendingEvent:
      canExecute: ->
        Meteor.isClient
      contentType: "event"
      apiCall: (content, fb, callback) ->
        fqlQuery = "SELECT uid,rsvp_status FROM event_member WHERE eid = " + content.sourceId + " AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
        fb.api.api("/fql",{q:fqlQuery}, (res) ->
          callback(_.map(_.filter(res.data, (u) -> u.rsvp_status == "attending"), (attending) -> {uid: attending.uid}))
        )

    eventComments: new class extends fbApiCaller
      canExecute: ->
        Meteor.isServer or Meteor.isClient
      contentType: "event"
      apiCall: (content, fb, callback) ->
        fqlQuery= "SELECT actor_id, message, post_id, created_time,attachment FROM stream WHERE source_id ="+content.sourceId
        fb.api.api("/fql", {q:fqlQuery}, (res) ->
          console.log(res)
          queue = new PowerQueue({maxProcessing: 5})
          _.each(res.data, (comment)->
            console.log(comment)
            queue.add((done) ->
              fb.api.api("/"+comment.actor_id, (res2) ->
                console.log(res2)
                Meteor.call("insertCommentFromFB", content, comment, res2, (err,res)->
                  console.log("insertCommentFromFB res", err,res)
                )
                done()
              )
            )
          )
          queue.onEnded= (param)->
            console.log("ended",param,this)

          queue.run()

        )
      cacheSeconds: 300
    eventStats: new class extends fbApiCaller
      canExecute: ->
        Meteor.isServer or Meteor.isClient
      permissons: null
      contentType: "event"
      apiCall: (event, fb, callback) ->
          limit = 1000
          this.fbapi(event.sourceId+"/attending",{fields: ["gender","installed"], limit: limit, summary:true}, (res) ->

            malecount = _.filter(res.data, (u) -> u.gender == "male").length
            femalecount = _.filter(res.data, (u) -> u.gender == "female").length
            voodoocount = _.filter(res.data, (u) -> u.installed).length
            return unless voodoocount > 1

            console.log("got stats and female, male counts", femalecount, malecount)
            totalAttending = res.summary?.count
            callback?(
              genderRatio: femalecount / (malecount + femalecount)
              voodooRatio: voodoocount / res.data.length
              voodooAttendingCount: if res.data.length > limit then Math.round(voodoocount*totalAttending) / limit else voodoocount
              attendingCount: totalAttending
            )
          )
      cacheSeconds: 300
      updateDB: (event, apiResult, callback) ->
        Meteor.call("updateContentStats", event._id, apiResult, (err,res) ->
          console.log("updated content stats on event")
          callback?(res)
        )
  }