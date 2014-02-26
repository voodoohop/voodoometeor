define "FacebookApiAbstraction", [], ->
  self =
    appUsersAttendingEvent:
      canExecute: ->
        Meteor.isServer or Meteor.isClient
      contentType: "event"
      apiCall: (content, fbapi, callback) ->
        query = "select uid from user where is_app_user=1 and uid in (select uid from event_member where eid = "+content.sourceId+" and rsvp_status='attending')"
        fbapi.api("/fql", {q: query}, (res) -> callback(res.data))
      updateCollection: (contentCollection, itemId, apiResult) ->
        contentCollection.update(itemId, {$set: {stats: {numAppUsersAttending: apiResult.length}}})

    friendsAttendingEvent:
      canExecute: ->
        Meteor.isClient
      contentType: "event"
      apicall: (content, fbapi, callback) ->
        fqlQuery = "SELECT uid,rsvp_status FROM event_member WHERE eid = " + content.sourceId + " AND uid IN (SELECT uid2 FROM friend WHERE uid1 = me())";
        fb.api.api("/fql",{q:fqlQuery}, (res) ->
          callback(_.map(_.filter(res.data, (u) -> u.rsvp_status == "attending"), (attending) -> {uid: attending.uid}))
        )
  return self