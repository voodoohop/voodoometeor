# handler to login
if (Meteor.isServer)
  require "Config", (config) ->
    Meteor.startup ->
      Accounts.loginServiceConfiguration.remove
        service: "tomfacebook"
      Accounts.loginServiceConfiguration.insert
        service: "tomfacebook",
        appId: config.current().facebook.appid,
        secret: config.current().facebook.appsecret

    Accounts.registerLoginHandler (options) ->
      console.log(options)
      return `undefined`  unless options.tomfacebook # don't handle

      serviceData =
        id: options.fbAuthResponse.userID
        accessToken: options.fbAuthResponse.accessToken
        email: options.email
        permissions: options.permissions
      opts =
        profile:
          name: options.username

      console.log("creating or updating user from fb with", serviceData, opts)
      userId = Accounts.updateOrCreateUserFromExternalService("tomfacebook", serviceData, opts).id
      console.log("got userId", userId)
      stampedToken = Accounts._generateStampedLoginToken();
      Meteor.users.update(userId,
        $push: {'services.resume.loginTokens': Accounts._hashStampedToken(stampedToken)}
        $set: opts
      )
      return {id: userId, token: stampedToken.token, tokenExpires: Accounts._tokenExpiration(stampedToken.when) }

else
  Meteor.loginWithTomFacebook = (userdetails, callback) ->
    console.log("logging in with", userdetails)
    Accounts.callLoginMethod
      methodArguments: [_.extend(userdetails, {tomfacebook:true})]
      userCallback: callback

