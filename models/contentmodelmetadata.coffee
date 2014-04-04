define "ContentMetaData", ["VoodoocontentModel"], (model) ->
  contentTypes = [
    {name: "event", color:"voodoocolor1", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true, width: 230, height: 230}
    {name: "video", color:"voodoocolor2", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: false, inlineplay: true,width: 345, height: 230, allowDynamicAspectRatio: true, maxWidth: 345, maxHeight: 460, minHeight: 230}
    {name: "photo", color: "voodoocolor3", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning", width: 345, height: 345, showtitle:false, allowDynamicAspectRatio: true, maxWidth: 345, maxHeight: 345}
    {name: "link", color: "voodoocolor4",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info", width: 230, height: 115}
    {name: "coverphoto", color: "voodoocolor5",title:null, icon:null, class:"label label-info", width: 575, height: 400, allowDynamicAspectRatio: true}
  ]
  console.log("registering contentcollection metadata helper")
  model.contentCollection.helpers
    metaData: ->
        self = this
        _.where(contentTypes, {name: self.type })?[0]
    bgcol: ->
      if this.metaData().colorfromweekday
        return "bgvoodoocolor"+([moment(new Date(this.post_date)).day() % 4+ 1] )
      else
        this.metaData.color


    fgcol:  ->
      if (this.metaData().colorfromweekday)
        return "fgvoodoocolor"+([moment(new Date(this.post_date)).day() % 5+ 1] )
      else
        this.metaData().color

  return contentTypes
require 'ContentMetaData', ->