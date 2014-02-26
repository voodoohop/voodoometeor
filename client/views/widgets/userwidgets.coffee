

Template.userLoginStatus.profileImage = ->
  fbid = Meteor.user()?.services?.tomfacebook?.id
  if (fbid)
    return "http://graph.facebook.com/"+fbid+"/picture"