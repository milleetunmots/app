(function($) {

  var ajaxSuccessRegex = /^\s*<!DOCTYPE/gmi;

  var onAjaxSuccess = function() {
    toastr.success('OK');
  };

  var onAjaxError = function(error) {
    toastr.error(error);
  };

  var initForm = function(form) {
    // display notifications
    var formErrorsListSelector = '#' + form.id + ' ul.errors';
    $(form).on('ajax:success', function(event) {
      var detail = event.detail;
      var data = detail[0];

      if (typeof(data) == typeof('')) {
        onAjaxSuccess();
      } else {
        var $newErrorsList = $(detail[0]).find(formErrorsListSelector);
        var $existingErrorsList = $(formErrorsListSelector);
        if ($existingErrorsList.length > 0) {
          $existingErrorsList.replaceWith($newErrorsList);
        } else {
          $(form).prepend($newErrorsList);
        }
        $newErrorsList.find('li').each(function() {
          onAjaxError($(this).text());
        });
      }
    }).on('ajax:error', function(event) {
      var detail = event.detail;
      var response = details[0];

      console.error(detail);
      onAjaxError(response);
    });

    // trigger submit on change
    $(form).find('input, textarea, select').change(function() {
      Rails.fire(form, 'submit');
    });
  };

  var init = function() {
    $('form[data-remote="true"]').each(function() {
      initForm(this);
    });
  };

  $(document).ready(init);

})(jQuery);

