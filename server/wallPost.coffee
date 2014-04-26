require ["VoodoocontentModel"], (model) ->
  insertPostFromEmbedly = (data,additionalFields = {}) ->
      console.log(data)
      pic = data.thumbnail_url
      if ! pic?
        if data.type =="photo"
          pic = data.original_url
      type = data.type
      type = "video" if type == "rich"
      return unless pic
      post =
        title: data.title ? data.original_url
        description: data.description
        link: data.original_url
        type: type
        post_date: moment().toJSON()
        source: "embedly"
        embedlyData: [data]
        picture: pic
      model.contentCollection.insert _.extend(post, additionalFields)

  Meteor.methods
    insertPostFromEmbedly: (data,additionalFields={}) ->
      insertPostFromEmbedly(data,additionalFields)
    insertWallPostFromEmbedly: (data) ->
      insertPostFromEmbedly(data,{wallPost:true})