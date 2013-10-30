define "ContentCommon", [], ->
  self = {}

  self.colors= [
    "#5cb85c"
    "#5bc0de"
    "#f0ad4e"
    "#428bca"
    "#5cb85c"
    "#f0ad4e"
    "#d9534f"
  ]

  self.getContenttypeMetadata = _.partial( (c) ->
    _.where(c.contentTypes, {name: this.type })?[0]
  , self)

  self.contentTypes = [
    {name: "event", color:"#428bca", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true}
    {name: "video", color:"#f0ad4e", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: true, inlineplay: true}
    {name: "photo", color: "#d9534f", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning"}
    {name: "link", color: "#5bc0de",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info"}
  ]

  self.helpers =
    bgcol: _.partial( (c) ->
      type = _.findWhere(c.contentTypes, {name: this.type})
      if (type.colorfromweekday)
        self.colors[moment(new Date(this.post_date)).day() % self.colors.length]
      else
        type.color
    , self)
    contentTypeMetaData: self.getContenttypeMetadata

  return self;

