Example usage:

```javascript
Template.xyz.value = function () {
  return ReactiveAsync("Template_xyz_value", function (w) {
  	someAsyncFunction(function (result) {
  		w.set(result);
  		w.done();
  	});
  }, {initial: ""});
};
```