require ["ClientShared"] , (mouseShare) ->

  if (Meteor.isServer)

    Meteor.setInterval( ->
      since = new Date(new Date().getTime() - 20000)
      mouseShare.sharedData.remove({lastActivity: {$lt: since}})
    , 1000)

  if (Meteor.isClient)

    self = this
    moveHandler = _.throttle((e) ->
      m = mouseShare.sharedData.findOne({owner: self.getUserId()})
      if (m)
        mouseShare.sharedData.update(m._id, {$set: {x: e.pageX, y: e.pageY, lastActivity: new Date()}})
      else
        mouseShare.sharedData.insert({owner: self.getUserId(), x: e.pageX, y: e.pageY, lastActivity: new Date()})
    ,20)

    $(document).on("mousemove",moveHandler)
    $(document).on("mousedown",moveHandler)


    Template.MouseCursorer.mice = ->
      mouseShare.sharedData.find()
    Template.MouseCursorer.isme = ->
      if this.owner == self.getUserId() then "mouseisme" else ""
    Template.MouseCursorer.getMouseLeft = ->
      this.x-25
    Template.MouseCursorer.getMouseTop = ->
      this.y-25
    Template.MouseCursorer.profileLink = ->
      fbid = Meteor.users.findOne(this.owner)?.services?.facebook?.id
      if fbid
        "http://www.facebook.com/profile.php?id=" + fbid
      else
        "#"

    Template.MouseCursorer.profileImgSmall = ->
      fbimg = Meteor.users.findOne(this.owner)?.services?.facebook?.id
      if fbimg?
        "http://graph.facebook.com/" + fbimg + "/picture?type=square"
      else
        "/images/soul_transparent_small.png"


    # anonymous spirits
    unless (Meteor.userId()?)
      console.log("inserting anonymous user")
      Session.set("anonymousUser", Math.random().toString(36).substring(7))


    this.getUserId = ->
      Meteor.userId() ? Session.get("anonymousUser")



