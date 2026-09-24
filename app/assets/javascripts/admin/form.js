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
    // rails-ujs sérialise le formulaire avant d'émettre `ajax:send` : c'est là
    // que la saisie part, et non au succès. Désarmer au succès mentirait sur
    // les modifications faites entre l'envoi et sa réponse — elles ne sont dans
    // aucune requête, mais le formulaire se croirait propre.
    $(form).on('ajax:send', function(event) {
      if (event.target !== form) return;
      formChanged = false;
    });

    $(form).on('ajax:success', function(event) {
      var detail = event.detail;
      var data = detail[0];

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
      // Le réarmement passe en premier : rien de ce qui suit ne doit pouvoir
      // laisser le formulaire réputé propre alors que la saisie n'est pas en
      // base. `ajax:send` l'a désarmé en pariant sur la réussite de l'envoi.
      formChanged = true;

      var detail = event.detail;
      var response = detail[0];

      console.error(detail);
      onAjaxError(response);
    });

    // trigger submit on change
    $(form).find(formTriggerSelector).change(function() {
      if ($(this).is(formTriggerExclusions.join(', '))) return;
      Rails.fire(form, 'submit');
    });
  };

  // Actualiser depuis form_freshness.js est un abandon volontaire de la saisie : sans
  // ce renoncement explicite, le garde beforeunload empilerait une confirmation native
  // par-dessus celle que l'utilisateur vient d'accepter.
  window.adminDiscardFormChanges = function() {
    formChanged = false;
  };

  // Quitte la page en s'assurant que la saisie en cours est enregistrée (cf.
  // admin/return_to.js) : une navigation immédiate avorterait l'auto-save en vol.
  // Si la fiche est périmée, form_freshness.js suspend l'envoi et propose d'actualiser :
  // la navigation demandée est alors abandonnée au profit du rechargement. Sur un refus,
  // l'enregistrement part quand même et la navigation suit son cours.
  window.adminNavigateAfterSave = function(url) {
    var go = function() {
      window.location.href = url;
    };

    if (!remoteForm || !formChanged) {
      go();
      return;
    }

    // On attend la retombée de l'envoi qui porte la saisie en cours, pas du
    // premier qui passe : un auto-save déjà en vol au moment du clic n'est pas
    // celui-là, et form_freshness.js peut avoir suspendu le nôtre derrière une
    // vérification. `formChanged`, désarmé à `ajax:send`, dit s'il reste de la
    // saisie qu'aucune requête n'emporte.
    var onComplete = function() {
      if (formChanged) return;

      $(remoteForm).off('ajax:complete', onComplete);
      go();
    };

    $(remoteForm).on('ajax:complete', onComplete);
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

