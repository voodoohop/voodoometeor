Meteor.startup ->
  console.log("content detail initing")


  updateHeadData = (data) ->
    SEO.set
      title: data.title
      meta:
        description: data.description
      og:
        title: data.title
        description: data.description




  require ["VoodoocontentModel","ContentItem", "FacebookClient", "EventManager"], (model, contentItem, fb, eventManager) ->
    console.log("adding content detail route")


    Router?.map ->
      this.route 'contentdetail',
        path: '/contentdetail/:_id'
        #template: 'contentdetail'
        layoutTemplate: 'mainlayout'
        #yieldTemplates:
        #  'contentdetailhead': {to: 'head'}
        #  'contentdetail': {to: 'contentdetail'}
        #waitOn: ->
        #  console.log("router subscribing to ",this.params._id)
        #  model.getDetails(this.params._id)

        after: ->
          id = this.params._id

          fb.onLoggedIn ->
              console.log("updating event stats", id)
              eventManager.updateEventStats(id)


        waitOn: ->
          console.log("ROUTE WAITON - subscribing to ",this.params._id)
          model.subscribeDetails(this.params._id)

        data: ->
          #console.log("getting content for:", this.params._id)
          console.log("got content for", this.params._id, res = model.getContentById(this.params._id))
          res

        #after: ->
        #  data = this.getData()
        #  console.log("updating header", this, data)



    Template.contentdetail.helpers(model.helpers)
    Template.contentdetail.helpers(contentItem.helpers)

    pagedown = new Markdown.Converter();
    Template.contentdetail.markdownDescription = ->
      if (this.description)
        pagedown.makeHtml(this.description)


    $(window).scroll( ->
      $(".detach-on-scroll").each ->
        #console.log($(this).offset())
        if ($(this).offset().top  < $(window).scrollTop())
          $(this).find(".detach-content").addClass("detached")
        else
          $(this).find(".detach-content").removeClass("detached")

    )


