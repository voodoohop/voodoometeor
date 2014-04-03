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
    Template.contentdetail.markdownDescription = ->
      id = this._id
      if (this.description)
        urlize(pagedown.makeHtml(this.description), {target:"_blank",django_compatible: false, trim: "http"})

    Template.contentdetail.eventToolBarData = ->
      {event: this.contentItem, minimized: true}

    Template.contentdetail.rendered = ->
      console.log("contentdetail rendered", this)
      event = this.data.contentItem
      if (!this.runEmbedly)
        this.runEmbedly=true
        Meteor.setTimeout(  ->
          console.log("running embedly on all links")
          $("#description_"+event._id+" a").embedly(
            key: "b5d3386c6d7711e193c14040d3dc5c07"
            method: null
            query:
              maxwidth: 200
              maxheight: 200
            display: (param) ->
              #console.log("embedly display", param)
              if (param.title?.length >0)
                UI.DomRange.insert(UI.render(Template.eventmedia.extend({data: param})).dom,$("#eventMedia_"+event._id)[0])
                param.$elem.tooltip({title: param.description?.substring(0,200)})
          )
        ,2000)

      updateHeadData(event)
      fb.onLoggedIn ->
          console.log("updating event stats", event.id)
          eventManager.updateEventStats(event)

    Template.eventmedia.rendered = ->
      #console.log(this)
      $(this.find("a")).tooltip()



