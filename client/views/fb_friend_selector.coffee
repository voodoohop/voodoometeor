define "FBFriendInviter", ["EventManager","FacebookClient", "VoodoocontentModel"], (eventManager, fb, model) ->

  self = {}
  self.RfacebookFriends = new Meteor.Collection(null)
  self.Rfilter = new ReactiveObject(["filter","inviting","loadingFriends"])
  self.Rfilter.filter = ""
  self.Rfilter.inviting = false
  self.Rfilter.loadingFriends = true

  self.noneSelected = false

  Template.fbeventinvite.rendered = ->
    console.log("event invite dialog rendered", this)
    self.inviteLadda = Ladda.create($("#invitesubmit")[0])
    self.inviteLadda.start()

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
      before: _.once ->
        console.log("ensuring logged in with create_event permission")
        fb.ensureLoggedIn( (success) ->
          if (success)
            fb.api.api("/fql",{q: "SELECT uid,name  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1 ORDER BY name"}, (res) ->
              console.log("throttled adding friends, no:", res.data.length)
              total = res.data.length
              processedno = 0
              #NProgress.configure({trickle: false, minimum: 0.0, maximum: 1.0})

              eachWithDelayPerN(res.data, 3,5, (i) ->
                self.RfacebookFriends.insert({ username: i.name, _id: ""+i.uid, id: ""+i.uid, selected: ! self.noneSelected })
                processedno++
                #NProgress.set( processedno / total )
                if (processedno % 5 == 0)
                  self.inviteLadda.setProgress(processedno / total )
              , ->  self.Rfilter.loadingFriends = false; self.inviteLadda.stop() )
            )
            console.log("got friends", self.RfacebookFriends)
        , ["create_event"])
        if (!fb.loggedIn)
          this.stop()
      waitOn: ->
        model.subscribeDetails(this.params._id)
      data: ->
        {event: model.getContentById(this.params._id)}

  Template.fbeventinvite_user.events
    "click .fs-anchor": ->
      self.RfacebookFriends.update(this.id,$set:{selected: ! this.selected})
  Template.fbeventinvite.events
    "change, keyup #fs-search-text": (e) ->
      text = $(e.target).val()
      self.Rfilter.filter = text
    "click #invitesubmit": ->
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
          self.inviteLadda.stop()

      processn(20)
      self.Rfilter.inviting = "inviting"
      self.inviteLadda.start()

    "click #selectnone": ->
      self.RfacebookFriends.update({}, {$set:{selected: false}}, {multi: true})
      self.noneSelected = true
    "click #selectall": ->
      self.RfacebookFriends.update({}, {$set:{selected: true}}, {multi: true})
      self.noneSelected = false

require "FBFriendInviter", (fbfi) ->