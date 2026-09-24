(function($) {

  var ajaxSuccessRegex = /^\s*<!DOCTYPE/gmi;
  var formChanged = false;
  var remoteForm;
  var formTriggerExclusions = [
    '#child_support_call0_resources_alternative_scripts',
    '#child_support_call1_resources_alternative_scripts',
    '#child_support_call2_resources_alternative_scripts',
    '#child_support_call3_resources_alternative_scripts',
    '#child_support_call0_resources_translated_videos'
  ];
  var formTriggerSelector = 'input, textarea, select';


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

  var onAjaxSuccess = function() {
    toastr.success('OK');
  };

  var onAjaxError = function(error) {
    toastr.error(error);
  };

  var initForm = function(form) {
    remoteForm = form;
    trackChanges(form);
    var formErrorsListSelector = '#' + form.id + ' ul.errors';
    $(form).on('ajax:success', function(event) {
      var detail = event.detail;
      var data = detail[0];
      formChanged = false;

      if (typeof(data) == typeof('')) {
        onAjaxSuccess();
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
    $(form).find(formTriggerSelector).change(function() {
      if ($(this).is(formTriggerExclusions.join(', '))) return;
      Rails.fire(form, 'submit');
    });
  };

  // Quitte la page en s'assurant que la saisie en cours est enregistrée (cf.
  // admin/return_to.js) : une navigation immédiate avorterait l'auto-save en vol.
  // Si la fiche est périmée, form_freshness.js bloque l'envoi et affiche son alerte :
  // on reste alors sur place, volontairement.
  window.adminNavigateAfterSave = function(url) {
    var go = function() {
      window.location.href = url;
    };

    if (!remoteForm || !formChanged) {
      go();
      return;
    }

    // `ajax:success` remet formChanged à false avant `ajax:complete` : l'alerte
    // beforeunload ne se déclenchera pas au moment de la navigation.
    $(remoteForm).one('ajax:complete', go);
    Rails.fire(remoteForm, 'submit');
  };

  var init = function() {
    $('form[data-remote="true"]').each(function() {
      initForm(this);
    });

    setupUnloadWarning();
  };

  $(document).ready(init);

})(jQuery);

