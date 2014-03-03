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
      apiCall: (content, fbapi, callback) ->
        fqlQuery = "SELECT uid,rsvp_status FROM event_member WHERE eid = " + content.sourceId + " AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
        fb.api.api("/fql",{q:fqlQuery}, (res) ->
          callback(_.map(_.filter(res.data, (u) -> u.rsvp_status == "attending"), (attending) -> {uid: attending.uid}))
        )

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