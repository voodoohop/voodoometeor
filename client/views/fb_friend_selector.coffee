#!
# * Facebook Friend Selector
# * Copyright (c) 2013 Coders' Grave - http://codersgrave.com
# * Version: 1.2.1
# * Requires:
# *   jQuery v1.6.2 or above
# *   Facebook Integration - http://developers.facebook.com/docs/reference/javascript/
# 
((window, document, $, undefined_) ->
  "use strict"
  fsOptions = {}
  running = false
  isShowSelectedActive = false
  windowWidth = 0
  windowHeight = 0
  selected_friend_count = 1
  search_text_base = ""
  content = undefined
  wrap = undefined
  overlay = undefined
  fbDocUri = "http://developers.facebook.com/docs/reference/javascript/"
  _start = ->
    if FB is `undefined`
      alert "Facebook integration is not defined. View " + fbDocUri
      return false
    fsOptions = $.extend(true, {}, defaults, fsOptions)
    fsOptions.onPreStart()
    if fsOptions.max > 0 and fsOptions.max isnt null
      fsOptions.showSelectedCount = true
      
      # if max. number selected, hide select all button
      fsOptions.showButtonSelectAll = false
    _dialogBox()
    fsOptions.onStart()
    return

  _close = ->
    wrap.fadeOut 400, ->
      content.empty()
      wrap.remove()
      _stopEvent()
      overlay.fadeOut 400, ->
        overlay.remove()
        return

      return

    running = false
    isShowSelectedActive = false
    fsOptions.onClose()
    return

  _submit = ->
    selected_friends = []
    $("input.fs-friends:checked").each ->
      selected_friends.push parseInt($(this).val().split("-")[1], 10)
      return

    if fsOptions.facebookInvite is true
      friends = selected_friends.join()
      FB.ui
        method: "apprequests"
        message: fsOptions.lang.facebookInviteMessage
        to: friends
      , (response) ->
        if response isnt null
          fsOptions.onSubmit selected_friends
          _close()  if fsOptions.closeOnSubmit is true
        return

    else
      fsOptions.onSubmit selected_friends
      _close()  if fsOptions.closeOnSubmit is true
    return

  _dialogBox = ->
    return  if running is true
    running = true
    #$("body").append overlay = $("<div id=\"fs-overlay\"></div>"), wrap = $("<div id=\"fs-dialog-box-wrap\"></div>")
    #wrap.append "<div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-n\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-ne\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-e\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-se\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-s\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-sw\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-w\"></div><div class=\"fs-dialog-box-bg\" id=\"fs-dialog-box-bg-nw\"></div>"
    #wrap.append content = $("<div id=\"fs-dialog-box-content\"></div>")
    #container = "<div id=\"fs-dialog\" class=\"fs-color-" + fsOptions.color + "\">" + "<h2 id=\"fs-dialog-title\"><span>" + fsOptions.lang.title + "</span></h2>" + "<div id=\"fs-filter-box\">" + "<div id=\"fs-input-wrap\">" + "<input type=\"text\" id=\"fs-input-text\" title=\"" + fsOptions.lang.searchText + "\" />" + "<a href=\"javascript:{}\" id=\"fs-reset\">Reset</a>" + "</div>" + "</div>" + "<div id=\"fs-user-list\">" + "<ul></ul>" + "</div>" + "<div id=\"fs-filters-buttons\">" + "<div id=\"fs-filters\">" + "<a href=\"javascript:{}\" id=\"fs-show-selected\"><span>" + fsOptions.lang.buttonShowSelected + "</span></a>" + "</div>" + "<div id=\"fs-dialog-buttons\">" + "<a href=\"javascript:{}\" id=\"fs-submit-button\" class=\"fs-button\"><span>" + fsOptions.lang.buttonSubmit + "</span></a>" + "<a href=\"javascript:{}\" id=\"fs-cancel-button\" class=\"fs-button\"><span>" + fsOptions.lang.buttonCancel + "</span></a>" + "</div>" + "</div>" + "</div>"
    #content.html container
    #console.log($('<div>').append(content.clone()).html())
    Template.fbfriendselectdialog?.rendered = ->
      console.log("rendering fbfriendselector")
      wrap = $("#fs-dialog-box-wrap")
      _getFacebookFriend()
      _resize true
      _initEvent()
      _selectAll()
      $(window).resize ->
        _resize false
        return

    UI.insert(UI.render(Template.fbfriendselectdialog), document.body)

    return

  _getFacebookFriend = ->
    $("#fs-user-list").append "<div id=\"fs-loading\"></div>"
    if fsOptions.addUserGroups and not fsOptions.facebookInvite
      FB.api "/", "POST",
        batch: [
          {
            method: "GET"
            relative_url: "me/friends"
          }
          {
            method: "GET"
            relative_url: "me/groups"
          }
        ]
      , (response) ->
        _parseFacebookFriends response
        return

    else
      FB.api "/me/friends", (response) ->
        _parseFacebookFriends response
        return

    return

  _parseFacebookFriends = (response) ->
    if response.error
      alert fsOptions.lang.fbConnectError
      _close()
      return false
    facebook_friends = []
    if fsOptions.addUserGroups and not fsOptions.facebookInvite
      facebook_friends = $.parseJSON(response[0].body).data
      $.merge facebook_friends, $.parseJSON(response[1].body).data
    else
      facebook_friends = response.data
    max_friend_control = fsOptions.maxFriendsCount isnt null and fsOptions.maxFriendsCount > 0
    facebook_friends = _shuffleData(response.data)  if fsOptions.showRandom is true or max_friend_control is true
    i = 0
    k = 0

    while i < facebook_friends.length
      break  if max_friend_control and fsOptions.maxFriendsCount <= k
      if $.inArray(parseInt(facebook_friends[i].id, 10), fsOptions.getStoredFriends) >= 0
        _setFacebookFriends i, facebook_friends, true
        k++
      i++
    j = 0

    while j < facebook_friends.length
      break  if max_friend_control and fsOptions.maxFriendsCount <= j + fsOptions.getStoredFriends.length
      continue  if $.inArray(parseInt(facebook_friends[j].id, 10), fsOptions.excludeIds) >= 0
      _setFacebookFriends j, facebook_friends, false  if $.inArray(parseInt(facebook_friends[j].id, 10), fsOptions.getStoredFriends) <= -1
      j++
    $("#fs-loading").remove()
    return

  _setFacebookFriends = (k, v, predefined) ->
    item = $("<li/>")
    link = "<a class=\"fs-anchor\" href=\"javascript://\">" + "<input class=\"fs-fullname\" type=\"hidden\" name=\"fullname[]\" value=\"" + v[k].name.toLowerCase().replace(/\s/g, "0") + "\" />" + "<input class=\"fs-friends\" type=\"checkbox\" name=\"friend[]\" value=\"fs-" + v[k].id + "\" />" + "<img class=\"fs-thumb\" src=\"https://graph.facebook.com/" + v[k].id + "/picture\" />" + "<span class=\"fs-name\">" + _charLimit(v[k].name, 15) + "</span>" + "</a>"
    item.append link
    $("#fs-user-list ul").append item
    _select item  if predefined
    return

  _initEvent = ->
    wrap.delegate "#fs-cancel-button", "click.fs", ->
      _close()
      return

    wrap.delegate "#fs-submit-button", "click.fs", ->
      _submit()
      return

    $("#fs-dialog input").focus(->
      $(this).val ""  if $(this).val() is $(this)[0].title
      return
    ).blur(->
      $(this).val $(this)[0].title  if $(this).val() is ""
      return
    ).blur()
    $("#fs-dialog input").keyup ->
      _find $(this)
      return

    wrap.delegate "#fs-reset", "click.fs", ->
      $("#fs-input-text").val ""
      _find $("#fs-dialog input")
      $("#fs-input-text").blur()
      return

    wrap.delegate "#fs-user-list li", "click.fs", ->
      _select $(this)
      return

    $("#fs-show-selected").click ->
      _showSelected $(this)
      return

    $(document).keyup (e) ->
      _close()  if e.which is 27 and fsOptions.enableEscapeButton is true
      return

    if fsOptions.closeOverlayClick is true
      overlay.css cursor: "pointer"
      overlay.bind "click.fs", _close
    return

  _select = (th) ->
    btn = th
    if btn.hasClass("checked")
      btn.removeClass "checked"
      btn.find("input.fs-friends").attr "checked", false
      selected_friend_count--
      $("#fs-select-all").text fsOptions.lang.buttonSelectAll  if selected_friend_count - 1 isnt $("#fs-user-list li").length
    else
      limit_state = _limitText()
      if limit_state is false
        btn.find("input.fs-friends").attr "checked", false
        return false
      selected_friend_count++
      btn.addClass "checked"
      btn.find("input.fs-friends").attr "checked", true
    _showFriendCount()
    return

  _stopEvent = ->
    $("#fs-reset").undelegate "click.fs"
    $("#fs-user-list li").undelegate "click.fs"
    selected_friend_count = 1
    $("#fs-select-all").undelegate "click.fs"
    return

  _charLimit = (word, limit) ->
    wlen = word.length
    return word  if wlen <= limit
    word.substr(0, limit) + "..."

  _find = (t) ->
    fs_dialog = $("#fs-dialog")
    container = $("#fs-user-list ul")
    search_text_base = $.trim(t.val())
    if search_text_base is ""
      $.each container.children(), ->
        $(this).show()
        return

      if fs_dialog.has("#fs-summary-box").length
        if selected_friend_count is 1
          $("#fs-summary-box").remove()
        else
          $("#fs-result-text").remove()
      return
    search_text = search_text_base.toLowerCase().replace(/\s/g, "0")
    elements = $("#fs-user-list .fs-fullname[value*=" + search_text + "]")
    container.children().hide()
    $.each elements, ->
      $(this).parents("li").show()
      return

    result_text = ""
    if elements.length > 0 and search_text_base > ""
      result_text = fsOptions.lang.summaryBoxResult.replace("{0}", "\"" + t.val() + "\"")
      result_text = result_text.replace("{1}", elements.length)
    else
      result_text = fsOptions.lang.summaryBoxNoResult.replace("{0}", "\"" + t.val() + "\"")
    unless fs_dialog.has("#fs-summary-box").length
      $("#fs-filter-box").after "<div id=\"fs-summary-box\"><span id=\"fs-result-text\">" + result_text + "</span></div>"
    else unless fs_dialog.has("#fs-result-text").length
      $("#fs-summary-box").prepend "<span id=\"fs-result-text\">" + result_text + "</span>"
    else
      $("#fs-result-text").text result_text
    return

  _resize = (is_started) ->
    windowWidth = $(window).width()
    windowHeight = $(window).height()
    docHeight = $(document).height()
    wrapWidth = wrap.width()
    wrapHeight = wrap.height()
    wrapLeft = (windowWidth / 2) - (wrapWidth / 2)
    wrapTop = (windowHeight / 2) - (wrapHeight / 2)
    if is_started is true
      overlay.css(
        "background-color": fsOptions.overlayColor
        opacity: fsOptions.overlayOpacity
        height: docHeight
      ).fadeIn "fast", ->
        wrap.css(
          left: wrapLeft
          top: wrapTop
        ).fadeIn()
        return

    else
      wrap.stop().animate
        left: wrapLeft
        top: wrapTop
      , 200
      overlay.css height: docHeight
    return

  _shuffleData = (array_data) ->
    j = undefined
    x = undefined
    i = array_data.length

    while i
      j = parseInt(Math.random() * i, 10)
      x = array_data[--i]
      array_data[i] = array_data[j]
      array_data[j] = x
    array_data

  _limitText = ->
    if selected_friend_count > fsOptions.max and fsOptions.max isnt null
      selected_limit_text = fsOptions.lang.selectedLimitResult.replace("{0}", fsOptions.max)
      $(".fs-limit").html "<span class=\"fs-limit fs-full\">" + selected_limit_text + "</span>"
      false

  _showFriendCount = ->
    if selected_friend_count > 1 and fsOptions.showSelectedCount is true
      selected_count_text = fsOptions.lang.selectedCountResult.replace("{0}", (selected_friend_count - 1))
      unless $("#fs-dialog").has("#fs-summary-box").length
        $("#fs-filter-box").after "<div id=\"fs-summary-box\"><span class=\"fs-limit fs-count\">" + selected_count_text + "</span></div>"
      else unless $("#fs-dialog").has(".fs-limit.fs-count").length
        $("#fs-summary-box").append "<span class=\"fs-limit fs-count\">" + selected_count_text + "</span>"
      else
        $(".fs-limit").text selected_count_text
    else
      if search_text_base is ""
        $("#fs-summary-box").remove()
      else
        $(".fs-limit").remove()
    return

  _resetSelection = ->
    $("#fs-user-list li").removeClass "checked"
    $("#fs-user-list input.fs-friends").attr "checked", false
    selected_friend_count = 1
    return

  _selectAll = ->
    if fsOptions.showButtonSelectAll is true and fsOptions.max is null
      $("#fs-show-selected").before "<a href=\"javascript:{}\" id=\"fs-select-all\"><span>" + fsOptions.lang.buttonSelectAll + "</span></a> - "
      wrap.delegate "#fs-select-all", "click.fs", ->
        if selected_friend_count - 1 isnt $("#fs-user-list li").length
          $("#fs-user-list li:hidden").show()
          _resetSelection()
          $("#fs-user-list li").each ->
            _select $(this)
            return

          $("#fs-select-all").text fsOptions.lang.buttonDeselectAll
          if isShowSelectedActive is true
            isShowSelectedActive = false
            $("#fs-show-selected").text fsOptions.lang.buttonShowSelected
        else
          _resetSelection()
          _showFriendCount()
          $("#fs-select-all").text fsOptions.lang.buttonSelectAll
        return

    return

  _showSelected = (t) ->
    container = $("#fs-user-list ul")
    allElements = container.find("li")
    selectedElements = container.find("li.checked")
    if selectedElements.length isnt 0 and selectedElements.length isnt allElements.length or isShowSelectedActive is true
      if isShowSelectedActive is true
        t.removeClass("active").text fsOptions.lang.buttonShowSelected
        container.children().show()
        isShowSelectedActive = false
      else
        t.addClass("active").text fsOptions.lang.buttonShowAll
        container.children().hide()
        $.each selectedElements, ->
          $(this).show()
          return

        isShowSelectedActive = true
    return

  defaults =
    max: null
    excludeIds: []
    getStoredFriends: []
    closeOverlayClick: true
    enableEscapeButton: true
    overlayOpacity: "0.3"
    overlayColor: "#000"
    closeOnSubmit: false
    showSelectedCount: true
    showButtonSelectAll: true
    addUserGroups: false
    color: "default"
    lang:
      title: "Friend Selector"
      buttonSubmit: "Send"
      buttonCancel: "Cancel"
      buttonSelectAll: "Select All"
      buttonDeselectAll: "Deselect All"
      buttonShowSelected: "Show Selected"
      buttonShowAll: "Show All"
      summaryBoxResult: "{1} best results for {0}"
      summaryBoxNoResult: "No results for {0}"
      searchText: "Enter a friend's name"
      fbConnectError: "You must connect to Facebook to see this."
      selectedCountResult: "You have choosen {0} people."
      selectedLimitResult: "Limit is {0} people."
      facebookInviteMessage: "Invite message"

    maxFriendsCount: null
    showRandom: false
    facebookInvite: true
    onPreStart: (response) ->
      null

    onStart: (response) ->
      null

    onClose: (response) ->
      null

    onSubmit: (response) ->
      null

  $.fn.fSelector = (options) ->
    @unbind "click.fs"
    @bind "click.fs", ->
      fsOptions = options
      _start()
      return

    this

  return
) window, document, jQuery


define "FBFriendInviter", ["EventManager","FacebookClient", "VoodoocontentModel"], (eventManager, fb, model) ->

  self = {}
  self.RfacebookFriends = new Meteor.Collection(null)
  self.Rfilter = new ReactiveObject(["filter","inviting","loadingFriends"])
  self.Rfilter.filter = ""
  self.Rfilter.inviting = false
  self.Rfilter.loadingFriends = true

  self.noneSelected = false

  Template.fbeventinvite.rendered = ->
    console.log("event invite dialog rendered")
    self.inviteLadda = Ladda.create($("#invitesubmit")[0])
    self.inviteLadda.start()

  self.friendQuery = (onlySelected = false) ->
    query = {}
    if onlySelected
      query = {selected: true}
    else
      if self.Rfilter.filter.length > 2
        query = { username: { $regex: self.Rfilter.filter, $options:"i" } }
    return query

  self.getFriends  = (onlySelected = false) ->
    console.log query = self.friendQuery(onlySelected)
    self.RfacebookFriends.find(query)

  Template.fbeventinvite.friends = self.getFriends
  Template.fbeventinvite.inviting = -> self.Rfilter.inviting
  Template.fbeventinvite.loadingFriends = -> self.Rfilter.loadingFriends

  Template.fbeventinvite_user.checked = -> if this.selected then "checked" else ""
  Router?.map ->
    this.route 'eventinvite',
      path: '/contentdetail/:_id/inviteFriends'
      template: 'fbeventinvite'
      layoutTemplate: 'mainlayout'
      before: _.once ->
        console.log("ensuring logged in with create_event permission")
        fb.ensureLoggedIn( (success) ->
          if (success)
            fb.api.api("/fql",{q: "SELECT uid,name  FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1 ORDER BY name"}, (res) ->
              console.log("throttled adding friends, no:", res.data.length)
              total = res.data.length
              processedno = 0
              #NProgress.configure({trickle: false, minimum: 0.0, maximum: 1.0})

              eachWithDelayPerN(res.data, 3,5, (i) ->
                self.RfacebookFriends.insert({ username: i.name, _id: ""+i.uid, id: ""+i.uid, selected: ! self.noneSelected })
                processedno++
                #NProgress.set( processedno / total )
                if (processedno % 5 == 0)
                  self.inviteLadda.setProgress(processedno / total )
              , ->  self.Rfilter.loadingFriends = false; self.inviteLadda.stop() )
            )
            console.log("got friends", self.RfacebookFriends)
        , ["create_event"])
      waitOn: ->
        model.subscribeDetails(this.params._id)
      data: ->
        {event: model.getContentById(this.params._id)}

  Template.fbeventinvite_user.events
    "click .fs-anchor": ->
      self.RfacebookFriends.update(this.id,$set:{selected: ! this.selected})
  Template.fbeventinvite.events
    "change, keyup #fs-search-text": (e) ->
      text = $(e.target).val()
      self.Rfilter.filter = text
    "click #invitesubmit": ->
      friends = self.getFriends(true).fetch()
      total = friends.length
      processedNo = 0
      processn = (n) ->
        removed = friends.splice(0, n)
        eachWithDelay( removed, 5, (r) ->
          self.RfacebookFriends.remove(r._id)
        )
        processedNo += removed.length
        self.inviteLadda.setProgress(processedNo / total)
        if friends.length > 0
          _.delay( ->
            processn(n)
          , 200)
        else
          self.inviteLadda.stop()

      processn(40)
      self.Rfilter.inviting = "inviting"
      self.inviteLadda.start()

    "click #selectnone": ->
      self.RfacebookFriends.update({}, {$set:{selected: false}}, {multi: true})
      self.noneSelected = true
    "click #selectall": ->
      self.RfacebookFriends.update({}, {$set:{selected: true}}, {multi: true})
      self.noneSelected = false

require "FBFriendInviter", (fbfi) ->