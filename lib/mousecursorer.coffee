require ["ClientShared"] , (mouseShare) ->

  if (Meteor.isClient)
    $(document).mousemove(_.throttle((e) ->
      m = mouseShare.sharedData.findOne({owner: Meteor.userId()})
      if (m)
        mouseShare.sharedData.update(m._id, {$set: {x: e.pageX, y: e.pageY, width: $(window).width(), height: $(window).height()}})
      else
        mouseShare.sharedData.insert({owner: Meteor.userId(), x: e.pageX, y: e.pageY, width: $(window).width(), height: $(window).height()})
    ,50)
    )

    Template.MouseCursorer.mice = ->
      mouseShare.sharedData.find()
    Template.MouseCursorer.getMouseLeft = ->
      this.x-25 #  (($(window).width() - mouse['w']) / 2 + mouse['x']) + 'px'
    Template.MouseCursorer.getMouseTop = ->
      this.y-25 #  (($(window).width() - mouse['w']) / 2 + mouse['x']) + 'px'
    Template.MouseCursorer.profileImgSmall = ->
      "http://graph.facebook.com/"+Meteor.users.findOne(this.owner)?.services?.facebook?.id+"/picture?type=square"