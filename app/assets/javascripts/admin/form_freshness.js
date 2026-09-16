(function($) {

  var STALE_MESSAGE = 'Attention, le contenu de cette fiche n’est pas à jour. ' +
    'L’enregistrement que vous allez effectuer risque d’écraser des données. ' +
    'Actualisez la page pour que la fiche soit à jour puis effectuez vos modifications.';

  var url;
  var loadedUpdatedAt;
  var bypassCheck = false;

  var fetchUpdatedAt = function() {
    return $.get(url).then(function(response) {
      return response.updated_at;
    });
  };

  var isStale = function() {
    return fetchUpdatedAt().then(function(currentUpdatedAt) {
      return currentUpdatedAt !== loadedUpdatedAt;
    });
  };

  var warn = function() {
    window.alert(STALE_MESSAGE);
  };

  // La fiche a pu être modifiée ailleurs pendant que l'onglet était ouvert : on
  // prévient dès la première modification, avant que la saisie ne soit perdue.
  var warnOnFirstChange = function(form) {
    $(form).one('input change', function() {
      isStale().then(function(stale) {
        if (stale) warn();
      });
    });
  };

  // Dernier rempart : la vérification étant asynchrone, on suspend l'envoi le temps
  // d'interroger la base, puis on le relance si la fiche est bien à jour.
  var blockStaleSubmit = function(form) {
    $(form).on('submit', function(event) {
      if (bypassCheck) {
        bypassCheck = false;
        return;
      }

      var submitter = event.originalEvent && event.originalEvent.submitter;
      event.preventDefault();

      var submit = function() {
        // requestSubmit déclenche l'évènement submit de façon synchrone : au retour,
        // le drapeau a été consommé — sauf si la validation HTML5 a bloqué l'envoi,
        // auquel cas on le désarme pour ne pas sauter la vérification suivante.
        bypassCheck = true;
        if (form.requestSubmit) {
          form.requestSubmit(submitter);
        } else {
          form.submit();
        }
        bypassCheck = false;
      };

      isStale().then(function(stale) {
        if (stale) {
          warn();
          return;
        }
        submit();
      }, submit); // vérification impossible : on ne bloque pas l'enregistrement
    });
  };

  var init = function() {
    var $marker = $('.js-form-freshness').first();
    if ($marker.length === 0) return;

    var form = $marker.closest('form')[0];
    if (!form) return;

    url = $marker.data('url');
    if (!url) return;

    fetchUpdatedAt().then(function(currentUpdatedAt) {
      loadedUpdatedAt = currentUpdatedAt;
      warnOnFirstChange(form);
      blockStaleSubmit(form);
    });
  };

  $(document).ready(init);

})(jQuery);
