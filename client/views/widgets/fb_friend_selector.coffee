define "FBFriendInviter", ["EventManager","FacebookClient", "VoodoocontentModel"], (eventManager, fb, model) ->

  self = {}
  self.RfacebookFriends = new Meteor.Collection(null)
  self.Rfilter = new ReactiveObject(["filter","inviting","loadingFriends"])
  self.Rfilter.filter = ""
  self.Rfilter.inviting = false
  self.Rfilter.loadingFriends = false

  self.noneSelected = false

  loginDep = new Deps.Dependency
  loginResult = undefined
  beforeDisplay = (callback = null) ->
    if loginResult
      callback?()
    else
      doFBLogin(callback)

  doFBLogin = _.once( (callback=null) ->
    fb.ensureLoggedIn( (success) ->
      loginResult = success
      loginDep.changed()
      callback?()
    , ["create_event"])
  )
  virtualLoginAndPermSubscription =  { ready: -> loginDep.depend(); loginResult }

  setButtonProgress = (progress) ->
    self.inviteLadda.start() unless self.inviteLadda.isLoading()
    self.inviteLadda.setProgress(progress)

  loadFriends = (option, callback = null) ->
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
          setButtonProgress(processedno / total)
      , ->  self.Rfilter.loadingFriends = false; self.loadedFriends = true; self.inviteLadda.stop(); callback?(); )
    )

  inviteFriends = (fbeventid, callback = null) ->
      friends = self.getFriends(true).fetch()
      total = friends.length
      processedNo = 0
      processn = (n) ->
        removed = friends.splice(0, n)
        _.each( removed, (r) ->
          self.RfacebookFriends.remove(r._id)
        )
        eventManager.invite(fbeventid, removed)
        processedNo += removed.length
        setButtonProgress(processedNo / total)
        if friends.length > 0
          _.delay( ->
            processn(n)
          , 200)
        else
          self.Rfilter.inviting = "doneInviting"
          self.inviteLadda.stop()
          callback?()
      processn(30)
      self.Rfilter.inviting = "inviting"
      self.inviteLadda.start()

  Template.fbeventinvite.doneInviting = ->
    self.Rfilter.inviting == "doneInviting"

  Template.fbeventinvite.rendered = ->
    console.log("event invite dialog rendered", this, this.data?.event?._id)
    if (self.inviteLadda)
      self.inviteLadda.stop()
    self.inviteLadda = Ladda.create($("#invitebutton_"+this.data?.event?._id)[0])
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

  #Template.fbeventinvite.friends = self.getFriends
  Template.fbeventinvite.inviting = -> self.Rfilter.inviting
  Template.fbeventinvite.loadingFriends = -> self.Rfilter.loadingFriends
  Template.fbeventinvite.disabledAttribute = ->
    return {disabled: true} if self.Rfilter.inviting == "doneInviting"
    {}

  Template.fbeventinvite_user.checked = -> if this.selected then "checked" else ""

  eventDetailSubscription = null
  Router?.map ->
    this.route 'eventinvite',
      path: '/contentDetail/:_id/inviteFriends'
      template: 'fbeventinvite'
      layoutTemplate: 'mainlayout'
      action: ->
        #console.log("fb_friend_selector_action", this, this.ready())
        #console.log("action",[eventDetailSubscription.ready(), virtualLoginAndPermSubscription.ready()])
        if this.ready()
          this.render()
      waitOn: ->
        console.log("friendselector waitOn called",this)
        #Deps.autorun (computation) ->
        #  computation.onInvalidate -> console.trace();
        id = this.params._id
        console.log("before hook event_invite router")
        beforeDisplay()
        console.log("calling model subscribeDetails ",id)
        eventDetailSubscription = model.subscribeDetails(id) unless eventDetailSubscription
        console.log("ready:",eventDetailSubscription.ready())
        [eventDetailSubscription, virtualLoginAndPermSubscription]
      data: ->
        if (!this.ready())
          return null;
        dta = {event: model.getContentById(this.params._id), friends: self.getFriends }
        console.log("friendselector data, ready:", this.ready(), dta)
        dta

  Template.fbeventinvite_user.events
    "click .fs-anchor": ->
      self.RfacebookFriends.update(this.id,$set:{selected: ! this.selected})

  Template.fbeventinvite.events
    "change, keyup #fs-search-text": (e) ->
      text = $(e.target).val()
      self.Rfilter.filter = text
    "click .inviteall": ->
      console.log("inviting all for",this.event)
      fbid = this.event.sourceId
      beforeDisplay( ->
          loadFriends ({fast: true}), ->
            inviteFriends(fbid)
      )

    "click .invitebutton": (e) ->
      console.log("invite button", this, this._id)

      if (self.loadedFriends)
        e.preventDefault()
        Router.go("contentdetail", { "_id": this.event._id} )
        inviteFriends(this.event.sourceId)

    "click .closebutton": ->
      Router.go("contentdetail", { "_id": this.event._id} )

    "click #selectnone": ->
      self.RfacebookFriends.update({}, {$set:{selected: false}}, {multi: true})
      self.noneSelected = true
    "click #selectall": ->
      self.RfacebookFriends.update({}, {$set:{selected: true}}, {multi: true})
      self.noneSelected = false

  return self

require "FBFriendInviter", (fbfi) ->