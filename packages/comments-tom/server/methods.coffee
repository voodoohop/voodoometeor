if Meteor.isServer
  Meteor.methods(
    insertCommentFromFB: (content, fbCommentData, fbActorData) ->
      if (Comment.find("fbPostId": comment.fbPostId).fetch().length > 0)
        return false
      comment =
        associationId: content._id
        userFbId: fbActorData.id
        username: fbActorData.name
        comment: fbCommentData.message
        path: "/contentDetail/"+content._id
        fbActorData: fbActorData
        attachment: fbCommentData.attachment
        createdAt: moment.unix(fbCommentData.created_time).toJSON()
        fbPostId: fbCommentData.post_id
        notify: []
        tags: []

      console.log("inserting comment from fb", comment)


      # Add the comment
      if (Comment.find("fbPostId": comment.fbPostId).fetch().length == 0)
        Comment.create comment
  )
