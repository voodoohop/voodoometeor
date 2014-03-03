mailparser = require("mailparser")
sys = require("sys")
console.log("extracting emails")

fetchmails= (startno, increment) ->
  console.log "initing fetchmail with startno,increment", startno, increment
  POP3Client = require("poplib");
  client = new POP3Client(110, "voodoohop.com", {  debug: false })

  client.on("connect", ->

    console.log("CONNECT success");
    client.login("colabore@voodoohop.com", "v00d00h0p");

  )

  client.on "login", (status) ->
    console.log("login", status)
    client.list()

  currentMsg = startno

  client.on "list", (status, msgcount, msgnumber, data, rawdata) ->
    if status is false
      console.log "LIST failed"
      client.quit()
    else
      console.log "LIST success with " + msgcount + " element(s)"
      if msgcount > 0
          client.retr currentMsg
      else
        client.quit()


  client.on "retr", (status, msgnumber, data, rawdata) ->
    if status is true
      #console.log "RETR success for msgnumber " + msgnumber
      #console.log("message", data)
      mp = new mailparser.MailParser()
      mp.on("headers", (headers) ->
        #console.log("HEADERS", headers);
        console.log(currentMsg, headers.from);
        currentMsg += increment
        client.retr currentMsg
      );
      mp.write(data)
      mp.end()
      #console.log("retrieving msg no",currentMsg)
      #client.quit()
    else
      console.log "RETR failed for msgnumber " + msgnumber
      client.quit()


totalmails = 8952
numthreads = 3
for i in [0..numthreads-1]
  fetchmails(totalmails-i,-numthreads) #backwards