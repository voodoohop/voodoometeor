define "FBFriendInviter", ["EventManager","FacebookClient", "VoodoocontentModel"], (eventManager, fb, model) ->

  self = {}
  self.RfacebookFriends = new Meteor.Collection(null)
  self.Rfilter = new ReactiveObject(["filter","inviting","loadingFriends"])
  self.Rfilter.filter = ""
  self.Rfilter.inviting = false
  self.Rfilter.loadingFriends = false

  self.noneSelected = false


  beforeDisplay = new ReactiveObject(["gotPermissions"])
  beforeDisplay.gotPermissions = undefined
  beforeDisplay.run = (callback) ->
    console.log("ensuring logged in with create_event permission")
    fb.ensureLoggedIn( (success) ->
          beforeDisplay.gotPermissions = success
          callback?(beforeDisplay.gotPermissions)
        , ["create_event"])
    return beforeDisplay

  beforeDisplay.ready = ->
    beforeDisplay.gotPermissions

  loadFriends = (option, callback) ->
    console.log("loading friends, assuming template rendered")
    self.inviteLadda.start()
    self.Rfilter.loadingFriends = true
    fb.api.api("/fql",{q: "SELECT uid,name  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1 ORDER BY name"}, (res) ->
      console.log("throttled adding friends, no:", res.data.length)
      total = res.data.length
      processedno = 0
      speed = if option?.fast then 0 else 3
      eachWithDelayPerN(res.data, speed , 5, (i) ->
        self.RfacebookFriends.insert({ username: i.name, _id: ""+i.uid, id: ""+i.uid, selected: ! self.noneSelected })

        processedno++
        if (processedno % 5 == 0)
          self.inviteLadda.setProgress(processedno / total )
      , ->  self.Rfilter.loadingFriends = false; self.inviteLadda.stop(); callback?(); )
    )

  inviteFriends = ->
      friends = self.getFriends(true).fetch()
      total = friends.length
      processedNo = 0
      processn = (n) ->
        removed = friends.splice(0, n)
        _.each( removed, (r) ->
          self.RfacebookFriends.remove(r._id)
        )
        processedNo += removed.length
        self.inviteLadda.setProgress(processedNo / total)
        if friends.length > 0
          _.delay( ->
            processn(n)
          , 200)
        else
          self.Rfilter.inviting = "doneInviting"
          self.inviteLadda.stop()
      processn(20)
      self.Rfilter.inviting = "inviting"
      self.inviteLadda.start()

  Template.fbeventinvite.doneInviting = ->
    self.Rfilter.inviting == "doneInviting"

  Template.fbeventinvite.rendered = ->
    console.log("event invite dialog rendered", this, this.data?.event?._id)
    self.inviteLadda = Ladda.create($("#invitebutton_"+this.data.event._id)[0])
    loadFriends() unless this.data.minimized

  self.friendQuery = (onlySelected = false) ->
    query = {}
    if onlySelected
      query = {selected: true}
    else
      if self.Rfilter.filter.length > 2
        query = { username: { $regex: self.Rfilter.filter, $options:"i" } }
    return query

  self.getFriends  = (onlySelected = false) ->
    console.log query = self.friendQuery(onlySelected)
    self.RfacebookFriends.find(query)

  Template.fbeventinvite.friends = self.getFriends
  Template.fbeventinvite.inviting = -> self.Rfilter.inviting
  Template.fbeventinvite.loadingFriends = -> self.Rfilter.loadingFriends
  Template.fbeventinvite.state = ->

  Template.fbeventinvite_user.checked = -> if this.selected then "checked" else ""

  Router?.map ->
    this.route 'eventinvite',
      path: '/contentdetail/:_id/inviteFriends'
      template: 'fbeventinvite'
      layoutTemplate: 'mainlayout'
      action: ->
        console.log("fb_friend_selector_action", this, this.ready())
        if this.ready()
          this.render()
      waitOn: ->
        [model.subscribeDetails(this.params._id), beforeDisplay.run()]
      data: ->
        {event: model.getContentById(this.params._id)}

  Template.fbeventinvite_user.events
    "click .fs-anchor": ->
      self.RfacebookFriends.update(this.id,$set:{selected: ! this.selected})

  Template.fbeventinvite.events
    "change, keyup #fs-search-text": (e) ->
      text = $(e.target).val()
      self.Rfilter.filter = text
    "click .inviteall": ->
      beforeDisplay.run ->
        if (beforeDisplay.gotPermissions)
          loadFriends {fast: true}, ->
            inviteFriends()
        else
          alert("no permission")

    "click .invitebutton": ->
      inviteFriends()


    "click #selectnone": ->
      self.RfacebookFriends.update({}, {$set:{selected: false}}, {multi: true})
      self.noneSelected = true
    "click #selectall": ->
      self.RfacebookFriends.update({}, {$set:{selected: true}}, {multi: true})
      self.noneSelected = false

require "FBFriendInviter", (fbfi) ->