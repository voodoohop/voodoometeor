Meteor.startup ->
  define "FacebookClient",[], ->

    console.log("initing fbclient")

    loggedInListeners = []



    self =
      loggedIn: undefined
      onLoggedIn: (callback) ->
        loggedInListeners.push(callback)
        if self.loggedIn
          callback(self.api)
      api: null
      ensureLoggedIn: (callback, perms) ->

        # wait if facebook is still determining whether or not the user is already connected
        if ! self.loggedIn?
          console.log("fb login status not determined yet... waiting", self.loggedIn)
          Meteor.setTimeout( ->
            self.ensureLoggedIn(callback, perms)
          , 200)
          return

        hasPerms = ! perms?  #if no perms argument specified hasPerms is true by default
        unless hasPerms
          hasPerms = _.intersection(_.keys(Meteor.user().services.tomfacebook.permissions), perms).length == perms.length
        console.log("loggedin?",self.loggedIn, "has all fb permissions?", hasPerms)
        if (self.loggedIn and hasPerms)
          callback?(true)
        else
          FB.login( (response) ->
            callback?(response.authResponse)
          , {scope: if perms then perms.join(",") else undefined });


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
          authResponse = response.authResponse
          FB.api '/me', (fbUser) ->
            console.log("fb client: got /me")
            FB.api "/me/permissions", (response) ->
              console.log("fb client: got /me/permissions")
              if response and response.data and response.data.length
                permissions = response.data.shift()
              console.log("expecting facebook_login message immediately")
              Meteor.loginWithTomFacebook(
                fbAuthResponse: authResponse
                username: fbUser.name
                permissions: permissions
                email: fbUser.email,
              ->
                #Meteor.connection.setUserId uid
                console.log("logged in, user:",Meteor.user())
                self.api = FB
                self.loggedIn = true
                _.each(loggedInListeners, (l) -> l(FB))
              )
#              Meteor.call("facebook_login", fbUser, accessToken, permissions, (err,uid) ->
#                console.log("facebook_login",err,uid)
#                unless err
#
#              )

        else


    return self


  e = document.createElement("script")
  e.async = true
  e.src = document.location.protocol + "//connect.facebook.net/en_US/all.js"
  document.getElementById("fb-root").appendChild e
  #Meteor.loginWithFacebook({requestPermissions: ["friends_events","user_events"]})


  require "FacebookClient",[], (res) -> console.log("fbclient",res)
