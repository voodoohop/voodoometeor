require "Config", (config) ->
  console.log("reading config")
  config.globalconfig.remove({})
  if ! config.isInitialized()
    config.globalconfig.insert
      facebook:
        pageaccesstoken: "CAAAAEinyRRYBAGYV8VTy8YJohLuaqFFqmZCVpsGEsY5bxwQf39xyTAyYpjoeC2gfZCrvk1MZBSacdiDAxHA5kGlLMbu0oLCzHkmqQVUc8Vdi98fOEcVd9OKrGpUwrROczZBUMQz5MjHUjGAJRSzIdf1JuGeNnMMinTZBQ1N8NPRYpeGNPpZALf"
        appid: "78013154582"
        appsecret: "e702a69b75c23dc41266d719cec3c408"
      embedly:
        key: "b5d3386c6d7711e193c14040d3dc5c07"
