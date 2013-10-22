require "VoodoocontentModel", (model) ->
  console.log("adding content detail route")
  Router.map ->
    this.route 'contentdetail',
      path: '/contentdetail/:_id'
      data: ->
        d = model.getContent
          query: this.params._id
        d.fetch()[0]


  Template.contentdetail.helpers(model.helpers)
