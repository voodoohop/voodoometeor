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
        image: data.picture



  require ["VoodoocontentModel","ContentItem", "FacebookClient", "EventManager"], (model, contentItem, fb, eventManager) ->
    console.log("adding content detail route")



    Router?.map ->
      this.route 'contentDetail',
        path: '/contentDetail/:_id'
        template: 'contentdetail'
        layoutTemplate: 'mainlayout'
        #yieldTemplates:
        #  'contentdetailhead': {to: 'head'}
        #  'contentdetail': {to: 'contentdetail'}
        #waitOn: ->
        #  console.log("router subscribing to ",this.params._id)
        #  model.getDetails(this.params._id)


        waitOn: ->
          console.log("ROUTE WAITON - subscribing to ",id = this.params._id)
          Deps.autorun (computation) ->
            computation.onInvalidate -> console.trace();

          res = Deps.nonreactive ->
            model.subscribeDetails(id)
          console.log("res subscribedatils.ready()", res.ready())
          res
        action: ->
          console.log("action, ready", this)
          if this.ready()
            console.log("rendering default screen")
            this.render()
          else
            console.log("rendering loading screen")
            this.render("loadingScreen")
        data: -> {id: this.params._id }
          #console.log("getting content for:", this.params._id)
          #console.log("got content for", this.params._id, res = model.getContentById(this.params._id))


        #after: ->
        #  data = this.getData()
        #  console.log("updating header", this, data)

    runEmbedly=false

    Template.contentdetail.eventData = ->
      console.log("contentdetail data helper", this)

      if (this.id)
        model.getContentById(this.id)

    Template.contentdetail.helpers(model.helpers)
    Template.contentdetail.helpers(contentItem.helpers)

    pagedown = new Markdown.Converter(false);
    Template.contentdetail.markdownDescription = ->
      console.log("got markdowned description", this.description)
      id = this._id
      if (this.description)
        if (!runEmbedly)
          runEmbedly=true
          Meteor.setTimeout(  ->
            console.log("running embedly on all links")
            $("#description_"+id+" a").embedly(
              key: "b5d3386c6d7711e193c14040d3dc5c07"
              method: null
              query:
                maxwidth: 200
                maxheight: 200
              display: (param) ->
                #console.log("embedly display", param)
                if (param.title?.length >0)
                  UI.insert(UI.render(Template.eventmedia.withData(param)),$("#eventMedia_"+id)[0])
                  param.$elem.tooltip({title: param.description?.substring(0,200)})
            )
          ,2000)
        urlize(pagedown.makeHtml(this.description), {target:"_blank",django_compatible: false, trim: "http"})

    Template.contentdetail.eventToolBarData = ->
      {event: model.getContentById(this.id), minimized: true}

    Template.contentdetail.rendered = ->
      console.log("contentdetail rendered", this)
      id = this.data.id
      updateHeadData(model.getContentById(this.data.id))
      fb.onLoggedIn ->
          console.log("updating event stats", id)
          eventManager.updateEventStats(id)

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

