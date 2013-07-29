define "VoodoocontentModel",[], ->

  self= this;

  self.contentBlockSize = 30;

  # content for rendering grid
  self.contentCollection =  new Meteor.Collection("voodoocontent")

  # content for detail page etc
  #self.contentDataCollection =  new Meteor.Collection("voodoocontentdata")

  self.getContent = (blockno=0,fields={}) -> self.contentCollection.find( {},
    skip: blockno * self.contentBlockSize
    limit: self.contentBlockSize
    fields: fields
  )
  self.getContentBySourceId = (sourceId) -> self.contentCollection.find({sourceId: sourceId})


#  self.getContentData = (id) -> contentDataCollection.find(id)


  if (Meteor.isServer)

    Meteor.publish "content", (blockno=0) ->
      console.log("client subscribed to content at blockno:"+blockno)
      self.getContent(blockno)

    Meteor.publish "contentbysourceid", (sourceid) ->
      console.log("client subscribed to content by sourceid:"+sourceid)
      self.getContentBySourceId(sourceid)

#    Meteor.publish "contentdata", (id) ->
#      console.log("client subscribed to contentdata, id:"+id)
#      self.getContentData(id)
#




  if (Meteor.isClient)
    self.contentsubscription = Meteor.subscribe "content"


  return this