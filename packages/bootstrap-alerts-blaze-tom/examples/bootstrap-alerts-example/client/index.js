Template.buttons.events({

    'click #m-success': function () {
        Alerts.add('Local drive [C:] formatted successfully!', 'success');
    },

    'click #m-info': function () {
        Alerts.add('Server recovered from crash.', 'info');
    },

    'click #m-warning': function () {
        Alerts.add('Please don\'t eat my cake!', 'warning');
    },

    'click #m-danger': function () {
        Alerts.add('Can\'t remove Admin user!', 'danger');
    },

    'click #m-success-1': function () {
        Alerts.add('Local drive [C:] formatted successfully!', 'success', {
            dismissable: false
        });
    },

    'click #m-info-1': function () {
        Alerts.add('Server recovered from crash.', 'info', {
            autoHide : 3000
        });
    },

    'click #m-warning-1': function () {
        Alerts.add('Please don\'t eat my cake!', 'warning',
            {
                alertsLimit : 1
            });
    },

    'click #m-danger-1': function () {
        Alerts.add('Can\'t remove Admin user!', 'danger', {
                fadeIn: 1000, fadeOut: 1000, autoHide: 3000
            });
    },

    'click #m-remove': function () {
        Alerts.removeSeen();
    }


});
