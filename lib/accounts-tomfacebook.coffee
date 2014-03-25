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

    Accounts.registerLoginHandler("tomfacebook", (options) ->
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
      createUserRes = Accounts.updateOrCreateUserFromExternalService("tomfacebook", serviceData, opts)
      console.log(createUserRes)
      userId = createUserRes.userId
      console.log("got userId", userId)
      Meteor.users.update(userId,
        $set: opts
      )
      return {userId: userId}
    )
else
  Meteor.loginWithTomFacebook = (userdetails, callback) ->
    console.log("logging in with", userdetails)
    Accounts.callLoginMethod
      methodArguments: [_.extend(userdetails, {tomfacebook:true})]
      userCallback: callback

