(function($) {

  var ajaxSuccessRegex = /^\s*<!DOCTYPE/gmi;
  var formChanged = false;
  var originalUpdatedAt;

  var trackChanges = function(form) {
    $(form).on('input change', function() {
      formChanged = true;
    });
  };

  var setupUnloadWarning = function() {
    $(window).on('beforeunload', function(event) {
      if (formChanged) {
        event.preventDefault();
        event.returnValue = '';
      }
    });
  };

  var fetchUpdatedAt = function() {
    return $.get('/child-support-updated-at/'+Number($('#child_support_id').val())).then(function(response) {
      originalUpdatedAt = response.updated_at;
    })
  };

  var checkForUpdates = function() {
    return $.get('/child-support-updated-at/'+Number($('#child_support_id').val())).then(function(response) {
      return response.updated_at !== originalUpdatedAt;
    })
  };

  var showUpdateAlert = function() {
    if (confirm('Les données ont été modifiées dans un autre onglet. Souhaitez-vous rafraîchir la page pour voir les dernières modifications ?')) {
      window.location.reload();
    }
  };

  var onAjaxSuccess = function() {
    toastr.success('OK');
  };

  var onAjaxError = function(error) {
    toastr.error(error);
  };

  var initForm = function(form) {
    fetchUpdatedAt();
    trackChanges(form);
    // display notifications
    var formErrorsListSelector = '#' + form.id + ' ul.errors';
    $(form).on('ajax:success', function(event) {
      var detail = event.detail;
      var data = detail[0];
      formChanged = false;

      if (typeof(data) == typeof('')) {
        onAjaxSuccess();
        fetchUpdatedAt();
        $(formErrorsListSelector).remove();
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
      formChanged = true;

      console.error(detail);
      onAjaxError(response);
    });

    // trigger submit on change
    $(form).find('input, textarea, select').change(function() {
      checkForUpdates().then(function(isUpdated) {
        if (isUpdated) {
          showUpdateAlert();
        } else {
          Rails.fire(form, 'submit');
        }
      });
    });
  };

  var init = function() {
    $('form[data-remote="true"]').each(function() {
      initForm(this);
    });

    setupUnloadWarning();
  };

  $(document).ready(init);

})(jQuery);

