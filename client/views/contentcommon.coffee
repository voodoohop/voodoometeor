define "ContentCommon", [], ->
  self = {}
  self.contentTypes = [
    {name: "event", color:"#428bca", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary"}
    {name: "video", color:"#f0ad4e", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label"}
    {name: "photo", color: "#d9534f", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning"}
    {name: "link", color: "#5bc0de",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info"}
  ]
  self.helpers =
    bgcol: _.partial( (c) ->
      _.findWhere(c.contentTypes, {name: this.type}).color
    , self)
    contentTypeMetaData: _.partial( (c) ->
        _.where(c.contentTypes, {name: this.type })?[0]
    , self)

  return self;

