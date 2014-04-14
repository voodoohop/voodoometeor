class Commentable extends Minimongoid
  
  # Go ahead and autosubscribe to the associated comments
  constructor: (attr = {}, parent = null) ->
    super(attr, parent)
    if Meteor.subscribe then Meteor.subscribe 'comments', @id

  comments: ->
    Comment.where associationId: @id

  commentCount: ->
    if @comments then @comments().length

  before_comment: (comment) ->
    comment
    
class Comment extends Minimongoid
  @_collection = new Meteor.Collection 'comments'

  if Meteor.isServer
    @_collection._ensureIndex({fbPostId:1})
  @unread: (tags = {}) ->
    # Grab all for current user
    selection = 
      notify:
        $in: [Meteor.userId()]
    
    # Filter down using tags
    if tags && _.isObject(tags) && _.keys(tags).length > 0
      selection.tags = tags

    @where selection

  clearNotification: ->
    @pull notify: Meteor.userId()

  commentPreview: ->
    @comment.substring(0, 20) + '...'

Comment._collection.allow
  insert: (userId, fundraiser) ->
    userId

  update: (userId, fundraiser, fields) ->
    userId

  remove: (userId, fundraiser) ->
    userId