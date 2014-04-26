define "ContentMetaData", ["VoodoocontentModel"], (model) ->
  contentTypes = [
    {name: "event", color:"bgvoodoocolor1", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true, width: 230, height: 230}
    {name: "video", color:"bgvoodoocolor2", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: false, inlineplay: true,width: 345, height: 230, allowDynamicAspectRatio: true, maxWidth: 345, maxHeight: 460, minHeight: 230}
    {name: "photo", color: "bgvoodoocolor3", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning", width: 345, height: 345, showtitle:false, allowDynamicAspectRatio: true, maxWidth: 345, maxHeight: 345}
    {name: "link", color: "bgvoodoocolor1",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info", showtitle: true, width: 230, height: 115}
    {name: "coverphoto", color: "bgvoodoocolor5",title:null, icon:null, class:"label label-info", width: 575, height: 400, allowDynamicAspectRatio: true}
    {name: "text", color: "bgvoodoocolor1", title:"Text"}
  ]
  console.log("registering contentcollection metadata helper")
  model.registerHelpers
    metaData: ->
        self = this
        _.where(contentTypes, {name: self.type })?[0]
    bgcol: ->
      if this.metaData().colorfromweekday
        return "bgvoodoocolor"+([moment(new Date(this.post_date)).day() % 4+ 1] )
      else
        this.metaData().color


    fgcol:  ->
      if (this.metaData().colorfromweekday)
        return "fgvoodoocolor"+([moment(new Date(this.post_date)).day() % 5+ 1] )
      else
        this.metaData().color

  return contentTypes
require 'ContentMetaData', ->