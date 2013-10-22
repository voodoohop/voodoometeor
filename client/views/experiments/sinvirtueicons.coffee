define "SinVirtueIcons",[], ->
  icons = [
    {file: "sin_gold", pecado: "avareza"}
    {file: "sin_pig", pecado: "gula"}
    {file: "sin_pistol", pecado: "ira"}
    {file: "sin_eye", pecado: "inveja"}
    {file: "sin_breasts", pecado: "luxuria"}
    {file: "sin_preguica", pecado: "preguica"}
    {file: "virtue1", virtude:"castidade"}
    {file: "virtue_can", virtude:"temperanca"}
    {file: "virtue_heart", virtude:"caridade"}
    {file: "virtue_mouse", virtude:"diligencia"}
    {file: "virtue_sandclock",virtude:"mansidao"}
    {file: "virtue_giving",virtude:"generosidade"}
  ]
  this.getRandom = ->
    "/images/sin_and_virtue_icons/"+icons[_.random(icons.length-1)].file + ".png"

  this.getByVirtueSin = (type, name) ->
    result = false
    _.each icons, (icon) ->
      if (icon[type] == name)
        result = "/images/sin_and_virtue_icons/"+icon.file + ".png"
    result
  return this

