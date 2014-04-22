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
        image: data.getPicture()
        type: "voodoohop:event"
        starttime: data.start_time
        endtime: data.end_time
        url: Meteor.absoluteUrl("contentDetail/"+data._id)
        location: data.location
        site_name: "VOODOOHOP"
      fb:
        app_id: "78013154582"



  require ["VoodoocontentModel","ContentItem", "FacebookClient", "EventManager", "LoadingTemplates"], (model, contentItem, fb, eventManager, loadingTemplates) ->
    console.log("adding content detail route")

    Template.contentdetailcaption.rendered = ->
      console.log("contentdetailcaption rendered", this)

    routeDefaults =
        layoutTemplate: 'mainlayout'
        yieldTemplates:
          'contentdetailcaption': {to: 'contentheader'}

        waitOn: ->
          console.log("ROUTE WAITON - subscribing to ",id = this.params._id)
          res = Deps.nonreactive ->
            model.subscribeDetails(id)
          console.log("res subscribedatils.ready()", res.ready())
          this.contentDetailSubscription = res
          res

        action:  ->
          console.log("action, ready", this)
          if this.ready()
            console.log("rendering default screen")
            this.render()
            #this.render({"contentdetailheader": {to: "header"}})
            self.loading = false
          else
            unless self.loading
              self.loading = true
              loadingTemplates.loadingContent(null)
              loadingTemplates.renderRandom(this)

        data: ->
          {contentItem: model.getContentById(this.params._id)}
        onStop: ->
          console.trace()
          console.log("contentdetail left route", this)
          model.stopDetailSubscription()
        fastRender: true



    Router?.map ->
      this.route 'contentdetail', _.extend(
        path: '/contentDetail/:_id/'
        template: 'contentdetail'
      ,routeDefaults)

      this.route 'updateticketinfo', _.extend(
        path: '/updateTicketInfo/:_id'
        template: 'updateticketinfo'
        onBeforeAction: ->
          console.log("route before, params", this.params)
          if this.params.hash
            Meteor.loginWithTokenFromHash(this.params.hash)
      ,routeDefaults)





    Template.contentdetail.helpers(model.helpers)
    Template.contentdetail.helpers(contentItem.helpers)


    pagedown = new Markdown.Converter(false);
    descriptionLinks = new ReactiveObject({links:[]})

    Template.contentdetail.markdownDescription = ->
      id = this._id
      if (this.description)
        res = urlize(pagedown.makeHtml(this.description), {target:"_blank",django_compatible: false, trim: "http"})
        descriptionLinks.links = _.filter(res.urls, (url) -> url.indexOf("://") != -1)
        console.log("got description links", res.urls)
        return res.html
    Template.contentdetail.eventToolBarData = ->
      {event: this.contentItem, minimized: true}

    Template.contentdetail.descriptionLinks = ->
      descriptionLinks.links

    Template.contentdetail.rendered = ->
      console.log("contentdetail rendered", this)
      event = this.data.contentItem

      updateHeadData(event)
      fb.onLoggedIn ->
          console.log("updating event stats", event.id)
          eventManager.updateEventStats(event)



    Template.backbutton.backRoute = ->
      Router.lastGridPath ? "/content/events/0"


    Template.contentdetail.voodoocomments = ->
      #console.log("VoodooComments",voodooComments)
      new VoodooComments({id: this._id})


    Template.contentdetail.mediaEmbedly= (options)->
        console.log("embedly helper", options)
        res= ReactiveAsync("embedly_"+options.hash.url, (w) ->
          Meteor.call("getEmbedlyData", options.hash.url, options.hash, (err, result) ->
            console.log("getEmbedlyData result",result)
            w.set(result)
            w.done()
          )
        , {initial: false})
        #console.log(res)
        res

