define "LoadingTemplates", [], ->

  self =
    numtemplates: 3
    contentCursor: new ReactiveObject(["cursor"])
    renderRandom: (renderer) ->
      tmpl = "loadingtemplate"+_.random(1,self.numtemplates)
      console.log("rendering loadingtemplate", tmpl)
      renderer.render(tmpl)
    loadingContent: (cursor) ->
      self.contentCursor.cursor = cursor

  Template.loadingtemplate1.content = -> self.contentCursor.cursor

  return self