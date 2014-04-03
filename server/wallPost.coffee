require ["VoodoocontentModel"], (model) ->
  Meteor.methods
    insertWallPostFromEmbedly: (data) ->
      console.log(data)
      pic = data.thumbnail_url
      if ! pic?
        if data.type =="photo"
          pic = data.original_url
      type = data.type
      type = "video" if type == "rich"
      return unless pic
      model.contentCollection.insert
        title: data.title ? data.original_url
        description: data.description
        link: data.original_url
        type: type
        post_date: moment().toJSON()
        source: "embedly"
        embedlyData: [data]
        wallPost: true
        picture: pic