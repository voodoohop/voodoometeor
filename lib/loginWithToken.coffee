Meteor.startup ->
  if Meteor.isServer
    Meteor.methods
      "generateLoginToken": (otherUserId = null) ->
        #if (otherUserId and (!Meteor.user().admin ))
        #  throw "Can't get login token for other person";
        if (Meteor.user())

          userId = if otherUserId then otherUserId else this.userId
          user = Meteor.users.findOne(userId)
          existingTokens = user.services?.resume?.loginTokens
          if (existingTokens? and (urlToken = _.find(existingTokens, (token) -> token.URLLogin? and token.token?)))
            console.log("has existing URL token, using", urlToken)
            urlToken.when = Date()
            Meteor.users.update(userId,{$set: {'services.resume.loginTokens': existingTokens}})
            return urlToken;
          else
            console.log("generating login token for ...", userId)
            stampedLoginToken = Accounts._generateStampedLoginToken()
            Meteor.users.update(userId, {$push: {'services.resume.loginTokens': _.extend({URLLogin: true, token: stampedLoginToken.token},Accounts._hashStampedToken(stampedLoginToken))}})
            console.log("hash stamped: ", Accounts._hashStampedToken(stampedLoginToken))
            console.log("generated hash")
            return stampedLoginToken;

      "userForLoginToken": (token) ->
        console.log("finding user for hash stamped token:", Accounts._hashStampedToken({token: token}))
        return Meteor.users.findOne({"services.resume.loginTokens": {$elemMatch: {hashedToken: Accounts._hashStampedToken({token: token}).hashedToken}}})

    Meteor.startup ->
      #Meteor.users.update("M8rWdggYRf9p4xNCX", {$set: {admin: true}})


  if Meteor.isClient
    Meteor.loginWithTokenFromHash = (hash) ->
              loginToken = hash.match(/^\/login-token\/(.*)$/)?[1]
              if (loginToken)
                console.log "login_token",loginToken

                Meteor.call("userForLoginToken", loginToken, (err,userForToken) ->
                  console.log("user:",userForToken)
                  if (userForToken?)
                    if (userForToken._id != Meteor.userId())
                      console.log("logging in with token:",loginToken)
                      Meteor.loginWithToken(loginToken)
                    else
                      console.log("ignoring login token since correct user logged in already")
                  else
                    console.log("no user found for token",loginToken)
                )