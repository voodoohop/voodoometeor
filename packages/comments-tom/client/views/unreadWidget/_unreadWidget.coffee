Template.unreadWidget.helpers
  triggerTemplate: (tpl) ->
    if tpl then Template[tpl] else Template['unreadWidgetTrigger']

  dropdownTemplate: (tpl) ->
    if tpl then Template[tpl] else Template['unreadWidgetDropdown']


Template.unreadWidgetDropdown.rendered = ->
  # Set the width of the dropdown to the computed value so the slide works correctly
  $('.unread-widget').on 'shown.bs.dropdown', (e) ->
    $('.comments-dropdown').css 'width', $('.comments-dropdown').width()

Template.unreadWidgetDropdown.events
  'click .clear-comments': (e) ->
    e.preventDefault()
    e.stopPropagation()

    tags = @tags
    count = Comment.unread(tags).length

    $('.comments-dropdown li.comment').each (i, e) ->
      # Slide each item out to right
      $e = $(e)
      $e.delay(i*80).animate
        marginLeft: (if parseInt($e.css("marginLeft"), 10) is 0 then $e.outerWidth() else 0)
      , ->
        # After the last one slides out, slide the menu up to close
        if i+1 is count
          $('.comments-dropdown').slideUp 300, ->
            # Finally, actually clear the notification in the database
            $('[data-toggle="dropdown"]').parent().removeClass('open')
            _.each Comment.unread(tags), (comment) ->
              comment.clearNotification()

Template.unreadWidgetDropdown.helpers
  disabled: ->
    @count > 0