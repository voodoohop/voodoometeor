require "Config", (config) ->
  console.log("reading config")
  if ! config.isInitialized()
    config.globalconfig.insert
      facebook:
        pageaccesstoken: "AAAAAEinyRRYBAATsjalchsrxm1uVZCLYS1vpVjtkI7fHgiO2L1LbaSJpC8dZB2GHlBhWOqUoZAW2aQT7H15HsXjGTkIeEWVZBz0LjTmms0O7IM8vZCUxS"
      embedly:
        key: "b5d3386c6d7711e193c14040d3dc5c07"
