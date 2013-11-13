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

  self.getContenttypeMetadata = _.partial( (c,ob = this) ->
    _.where(c.contentTypes, {name: ob.type })?[0]
  , self)

  self.sortTypes = [
    {name: "post_date", title:"Post Date", icon:"glyphicon glyphicon-calendar", accessor: (e) -> e?.post_date}
    {name: "like_count", title:"Likes", icon:"glyphicon glyphicon-heart", accessor: (e) -> e?.like_count}
  ]

  self.contentTypes = [
    {name: "event", color:"#428bca", title:"Events", icon:"glyphicon glyphicon-calendar", class:"label label-primary", showtitle: true, colorfromweekday: true, width: 250, height: 280}
    {name: "video", color:"#f0ad4e", title:"Videos", icon:"glyphicon glyphicon-facetime-video", class:"label-success label",showtitle: true, inlineplay: true,width: 510, height: 280}
    {name: "photo", color: "#d9534f", title:"Photos", icon:"glyphicon glyphicon-picture", class:"label label-warning", width: 250, height: 350}
    {name: "link", color: "#5bc0de",title:"Links", icon:"glyphicon glyphicon-link", class:"label label-info", width: 250, height: 140}
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

