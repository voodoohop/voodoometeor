var store = {};

ReactiveAsync = function (uniqueId, workspace, options) {
  uniqueId = uniqueId + (Deps.currentComputation && Deps.currentComputation._id);

  var opts = _.extend({
    initial: undefined
  }, options);

  if (!_.has(store, uniqueId)) {
    store[uniqueId] = {
      dep: new Deps.Dependency,
      state: "idle",
      val: opts.initial,
      newVal: opts.initial
    };
  }

  var o = store[uniqueId];

  o.dep.depend();

  if (o.state === "idle") {
    o.state = "working";
    o.newVal = opts.initial;

    _.isFunction(workspace) && workspace({
      done: function () {
        o.state = "done";
        this.flush();
      },
      get: function () {
        return o.newVal;
      },
      set: function (setVal) {
        o.newVal = setVal;
      },
      getCurrent: function () {
        return o.val;
      },
      flush: function () {
        o.val = o.newVal;
        o.dep.changed();
      }
    });
  }

  if (o.state === "done") {
    o.state = "idle";
  }

  return o.val;
};