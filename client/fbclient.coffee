require ["EventManager"], (eventmanager) ->

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
        accessToken = response.authResponse.accessToken
        FB.api '/me', (fbUser) ->
          FB.api "/me/permissions", (response) ->
            if response and response.data and response.data.length
              permissions = response.data.shift()
            Meteor.call("facebook_login", fbUser, accessToken, permissions, (err,uid) ->
              unless err
                Meteor.connection.setUserId uid

            )
        eventmanager.fbLoggedin(FB);
      else
        if (response.status == 'not_authorized')
          FB.login();
        else
          FB.login();


  Meteor.startup ->
    e = document.createElement("script")
    e.async = true
    e.src = document.location.protocol + "//connect.facebook.net/en_US/all.js"
    document.getElementById("fb-root").appendChild e
    #Meteor.loginWithFacebook({requestPermissions: ["friends_events","user_events"]})



