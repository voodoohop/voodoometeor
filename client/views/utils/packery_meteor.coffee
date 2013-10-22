define "PackeryMeteor", [], ->
  PackeryMeteor =
    # Singleton instance
      inst: null

    # Use underscore's _.once functio to make sure this is only called
    # once. Subsequent calls will just return.
      initonce: _.once((container, itemSelector, callback) ->
        console.log("initing packery!!!")
        PackeryMeteor.inst = new Packery(container,
          gutter: 0
          itemSelector: itemSelector
        )
        callback()
      )

      update: _.debounce( ->
        PackeryMeteor.updateDebounced()
      , 100)

      updateDebounced: ->
        self = this
        if @inst
          # Wait until dependencies are flushed and then force a layout
          # on our packery instance
          Deps.afterFlush ->
            self.inst.reloadItems()
            self.inst.layout()

      init: _.debounce( (container, itemSelector, callback ) ->
        PackeryMeteor.initonce(container, itemSelector, callback)
      , 100)

      observeChanges: (cursor) ->

        # Call observeChanges after the {{#each}} helper has had a chance
        # to execute because it also uses observeChanges and we want our code
        # to run after Meteor's. This way Spark will be done with all the
        # rendering work by the time this code is called.
        console.log("packery registering change observer")
        cursor.observeChanges
          addedBefore: (id) ->
            PackeryMeteor.update()

          movedBefore: (id) ->
            PackeryMeteor.update()

          removed: (id) ->
            PackeryMeteor.update()
