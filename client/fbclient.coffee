Meteor.startup ->
  define "FacebookClient",[], ->

    console.log("initing fbclient")

    Session.set("fbloggedin",false)
    loggedInListeners = []



    self =
      loggedIn: false
      onLoggedIn: (callback) ->
        loggedInListeners.push(callback)
        if self.loggedIn
          callback(self.api)
      api: null
      ensureFBLogin: (callback) ->


    window.fbAsyncInit = ->
      # init the FB JS SDK
      FB.init(
        appId      : '78013154582'                        # App ID from the app dashboard
        channelUrl : Meteor.absoluteUrl '/channel.html'   # Channel file for x-domain comms
        status     : true                                 # Check Facebook Login status
        xfbml      : true                                  # Look for social plugins on the page
      )

      console.log("initing fb api")

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
                console.log("facebook_login",err,uid)
                unless err
                  Meteor.connection.setUserId uid
                  #console.log("calling event manager")
                  self.api = FB
                  self.loggedIn = true
                  Session.set("fbloggedin",true);
                  _.each(loggedInListeners, (l) -> l(FB))
              )

        else
          if (response.status == 'not_authorized')
            FB.login();
          else
            FB.login();


    return self


  e = document.createElement("script")
  e.async = true
  e.src = document.location.protocol + "//connect.facebook.net/en_US/all.js"
  document.getElementById("fb-root").appendChild e
  #Meteor.loginWithFacebook({requestPermissions: ["friends_events","user_events"]})


  require "FacebookClient",[], (res) -> console.log("fbclient",res)
