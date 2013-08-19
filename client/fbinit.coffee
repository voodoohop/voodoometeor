
window.fbAsyncInit = ->
  # init the FB JS SDK
  FB.init(
    appId      : '78013154582'                        # App ID from the app dashboard
    channelUrl : Meteor.absoluteUrl '/channel.html'   # Channel file for x-domain comms
    status     : true                                 # Check Facebook Login status
    xfbml      : true                                  # Look for social plugins on the page
  )
  FB.Event.subscribe 'auth.authResponseChange', (response) ->
    if (response.status == 'connected')
      console.log("fb client connect")
      console.log(response)
#      Meteor.loginWithFacebooktom()
    else
      if (response.status == 'not_authorized')
        FB.login();
      else
        FB.login();





#Oauth.registerService 'facebooktom', 2, null, ->
#  console.log("custom facebook login service called")
