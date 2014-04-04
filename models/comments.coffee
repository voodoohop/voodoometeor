class @VoodooComments extends Commentable
  before_comment: (comment) ->
    console.log("before comment", comment)
    comment
