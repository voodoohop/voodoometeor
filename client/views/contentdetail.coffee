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
          console.log("ROUTE WAITON - subscribing to ",id = this.params._id)
          Deps.nonreactive ->
            model.subscribeDetails(id)

        action: ->
          if this.ready()
            this.render()
          else
            this.render("loadingScreen")
        data: ->
          #console.log("getting content for:", this.params._id)
          #console.log("got content for", this.params._id, res = model.getContentById(this.params._id))
          model.getContentById(this.params._id)

        #after: ->
        #  data = this.getData()
        #  console.log("updating header", this, data)



    Template.contentdetail.helpers(model.helpers)
    Template.contentdetail.helpers(contentItem.helpers)

    pagedown = new Markdown.Converter(true);
    Template.contentdetail.markdownDescription = ->
      id = this._id
      if (this.description)
        Meteor.setTimeout( ->
          console.log("running embedly on all links")
          $("#description_"+id+" a").embedly(
            key: "b5d3386c6d7711e193c14040d3dc5c07"
            method: null
            query:
              maxwidth: 200
              maxheight: 200
            display: (param) ->
              console.log("embedly display", param)
              if (param.title?.length >0)
                UI.insert(UI.render(Template.eventmedia.withData(param)),$("#eventMedia_"+id)[0])
                param.$elem.tooltip({title: param.description?.substring(0,200)})
          )
        ,1000)
        pagedown.makeHtml(this.description)

    Template.eventmedia.rendered = ->
      #console.log(this)
      $(this.find("a")).tooltip()
    $(window).scroll( ->
      $(".detach-on-scroll").each ->
        #console.log($(this).offset())
        if ($(this).offset().top  < $(window).scrollTop())
          $(this).find(".detach-content").addClass("detached")
        else
          $(this).find(".detach-content").removeClass("detached")

    )


    Template.mootForum.currentURL = ->
      Meteor.absoluteUrl(location.pathname)

