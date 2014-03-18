Meteor.startup ->
  define "FacebookClient",[], ->

    console.log("initing fbclient")

    loggedInListeners = []



    self = new ReactiveObject(["RloggedIn"])
    self.setLoggedInStatus = (s) ->
      self.loggedIn = s
      self.RloggedIn = s
      if s
        _.each(loggedInListeners, (l) -> l(FB, s))

    self.loggedIn = undefined
    self.onLoggedIn= (callback) ->
        loggedInListeners.push(callback)
        if self.loggedIn?
          callback(self.api, self.loggedIn)
    self.api = null

    processFBAuthResponse = (response, callback=null) ->
        if (response.status == 'connected')
          console.log("fb client connect")
          console.log(response)
          authResponse = response.authResponse
          FB.api '/me', (fbUser) ->
            console.log("fb client: got /me")
            FB.api "/me/permissions", (response) ->
              console.log("fb client: got /me/permissions")
              if response and response.data and response.data.length
                permissions = response.data.shift()
              console.log("expecting facebook_login message immediately")

              finallyLoggedIn = ->
                  console.log("logged in, user:",Meteor.user())
                  self.api = FB
                  self.setLoggedInStatus(true)
                  callback?(true)
              unless Meteor.userId()
                Meteor.loginWithTomFacebook(
                  fbAuthResponse: authResponse
                  username: fbUser.name
                  permissions: permissions
                  email: fbUser.email,
                -> finallyLoggedIn())
              else
                #should check here if facebook user is equal to logged in user of meteor (token login)
                finallyLoggedIn()


    self.doLogin = (callback, perms) ->
      FB.login( (response) ->
        processFBAuthResponse response, ->
          callback?(response.authResponse)
        , {scope: if perms then perms.join(",") else undefined });

    self.ensureLoggedIn= (callback, perms, loginPopUp = false) ->
        # wait if facebook is still determining whether or not the user is already connected
        if ! self.loggedIn?
          console.log("fb login status not determined yet... waiting", self.loggedIn)
          Meteor.setTimeout( ->
            self.ensureLoggedIn(callback, perms, true)
          , 200)
          if (! loginPopUp)
            return
        hasPerms = ! perms?  #if no perms argument specified hasPerms is true by default
        if Meteor.user() and ! hasPerms
          hasPerms = _.intersection(_.keys(Meteor.user().services.tomfacebook.permissions), perms).length == perms.length
        console.log("loggedin?",self.loggedIn, "has all fb permissions?", hasPerms)
        if (self.loggedIn and hasPerms)
          callback?(true)
        else
          FB.login( (response) ->
            processFBAuthResponse response, ->
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
      FB.getLoginStatus (response) ->
        console.log("fb login status", response)
        if (response.status != "connected")
          self.setLoggedInStatus(false)

      FB.Event.subscribe 'auth.authResponseChange', (response) ->
        processFBAuthResponse(response)


    return self


  e = document.createElement("script")
  e.async = true
  e.src = document.location.protocol + "//connect.facebook.net/pt_BR/all.js"
  document.getElementById("fb-root").appendChild e
  #Meteor.loginWithFacebook({requestPermissions: ["friends_events","user_events"]})


  require "FacebookClient",[], (res) -> console.log("fbclient",res)
