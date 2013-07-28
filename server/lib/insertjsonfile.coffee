
@fs = Npm.require("fs")

@insertSample = (jsondata) ->
    Fiber(->
      EventsModel.insert
        name: "Sample doc"
        data: jsondata
    ).run()

@insertJSONfile = (file,collection) ->
    data = fs.readFileSync file
    jsondata = JSON.parse(data)

    for row in jsondata
      console.log(JSON.stringify(row))
      collection.insert (row)
