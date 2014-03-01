#Bootstrap Alerts

Meteor Package for [Bootstrap Alerts](http://getbootstrap.com/components/#alerts). Live example [here](http://bootstrap-alerts-example.meteor.com).

## Basics

```javascript
Alerts.add('Database reading error!'); 
```

![Example image](https://raw.github.com/asktomsk/bootstrap-alerts/master/examples/bootstrap-alerts-example/danger.png)


Bootstrap 3.0 contains 4 types of builtin alerts: success, info, warning, danger.

You can easelly add such sort of notifications to your [Meteor](https://meteor.com) project by using this package.

## Usage

Install package from [Atmosphere](https://atmosphere.meteor.com/wtf/app):

```sh
mrt add bootstrap-alerts
```

Put template string to top of your page: 

```html
{{> bootstrapAlerts}}
```
Display alerts from JavaScript code:

```javascript
Alerts.add('Database reading error!'); // default type is 'danger'
Alerts.add('Local drive [C:] formatted successfully!', 'success');
Alerts.add('Server recovered from crash.', 'info');
Alerts.add('Please don\'t eat my cake!', 'warning');
Alerts.add('Can\'t remove Admin user!', 'danger');
```

## Customisation

### Default options is:

```javascript
    defaultOptions: {

        /**
         * Button with cross icon to hide (close) alert
         */
        dismissable: true,

        /**
         * CSS classes to be appended on each alert DIV (use space for separator)
         */
        classes: '',

        /**
         * Hide alert after delay in ms or false to infinity
         */
        autoHide: false,

        /**
         * Time in ms before alert fully appears
         */
        fadeIn: 200,

        /**
         * If autoHide enabled then fadeOut is time in ms before alert disappears
         */
        fadeOut: 600,

        alertsLimit : 3
    }
```
You can override from javaScript code, e.g.:

```javascript
Alerts.defaultOptions.alertsLimit = 1;
```

### Function Alerts.add

The prototype of ``` Alerts.add``` function is:

```javascript
 /**
     * Add an alert
     *
     * @param message (String) Text to display.
     * @param mode (String) One of bootstrap alerts types: 'success', 'info', 'warning', 'danger' (default)
     * @param options (Object) Options if required to override some of default ones.
     *                          See Alerts.defaultOptions for all values.
     */
    add: function (message, mode, options)
```

The ```mode``` and ```options``` parameters are optional.

The ```options``` parameter provides customization for current alert. Example:

```javascript
Alerts.add('Can\'t remove Admin user!', 'danger', {
                fadeIn: 1000, fadeOut: 1000, autoHide: 3000
            });
```

## Removing Alerts

In case if you use common template for your application and alerts should be removing after changing a page you should call ``` Alerts.removeSeen() ``` function:

```javascript 
/**
     * Call this function before loading a new page to clear errors from previous page
     * Best way is using Router filtering feature to call this function
     */
    removeSeen: function ()
```

This is example of [iron-router](https://github.com/EventedMind/iron-router#using-hooks) ```before``` hook:

```javascript 

Router.before(function () { Alerts.removeSeen(); });

```

## License

MIT
