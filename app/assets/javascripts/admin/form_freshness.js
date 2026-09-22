(function($) {

  var STALE_MESSAGE = 'Attention, le contenu de cette fiche n’est pas à jour. ' +
    'L’enregistrement que vous allez effectuer risque d’écraser des données. ' +
    'Actualisez la page pour que la fiche soit à jour puis effectuez vos modifications.';

  var url;
  var baseline; // Promise<String> : l'updated_at de l'état que la page reflète.
  var savesInFlight = 0;
  var checkInFlight = false;
  var bypassCheck = false;

  var fetchUpdatedAt = function() {
    return $.get(url).then(function(response) {
      return response.updated_at;
    });
  };

  // Nos propres enregistrements font avancer updated_at : sans recalage, la fiche se
  // croirait périmée dès la première sauvegarde.
  var refreshBaseline = function() {
    var previous = baseline;

    // Référence injoignable : on conserve la précédente plutôt que de laisser une
    // promesse rejetée empoisonner toutes les vérifications suivantes.
    baseline = fetchUpdatedAt().then(null, function() { return previous; });
    return baseline;
  };

  // On chaîne sur la promesse plutôt que sur une valeur figée : l'auto-save enchaîne
  // les envois, et une vérification peut partir avant que le recalage soit revenu.
  var isStale = function() {
    // Tant qu'un de nos enregistrements est en vol, updated_at va avancer de notre
    // fait : comparer maintenant reviendrait à prendre notre propre sauvegarde pour
    // une modification concurrente.
    if (savesInFlight > 0) return $.Deferred().resolve(false).promise();

    return baseline.then(function(baselineUpdatedAt) {
      return fetchUpdatedAt().then(function(currentUpdatedAt) {
        return currentUpdatedAt > baselineUpdatedAt;
      });
    });
  };

  var warn = function() {
    window.alert(STALE_MESSAGE);
  };

  // La fiche a pu être modifiée ailleurs pendant que l'onglet était ouvert : on
  // prévient dès la modification, avant que la saisie ne soit perdue. `input` se
  // déclenche à chaque caractère, d'où le garde qui limite à une vérification en vol.
  var warnOnChange = function(form) {
    $(form).on('input change', function() {
      if (checkInFlight) return;
      checkInFlight = true;

      isStale().then(function(stale) {
        checkInFlight = false;
        if (stale) warn();
      }, function() {
        checkInFlight = false;
      });
    });
  };

  // Dernier rempart : la vérification étant asynchrone, on suspend l'envoi le temps
  // d'interroger la base, puis on le relance si la fiche est bien à jour.
  //
  // Sur un formulaire remote, annuler l'évènement `submit` ne sert à rien : rails-ujs
  // branche handleRemote en délégation sur `document` et ignore defaultPrevented, si
  // bien que la requête partait quand même — et la relance en déclenchait une seconde.
  // Le hook `ajax:before`, lui, est bien annulable.
  var blockStaleSubmit = function(form) {
    var remote = form.getAttribute('data-remote') === 'true';

    $(form).on(remote ? 'ajax:before' : 'submit', function(event) {
      // Les évènements rails-ujs remontent : on ignore ceux d'un élément remote
      // imbriqué, qui n'est pas l'enregistrement de la fiche.
      if (event.target !== form) return;

      if (bypassCheck) {
        bypassCheck = false;
        return;
      }

      var submitter = event.originalEvent && event.originalEvent.submitter;
      event.preventDefault();

      var submit = function() {
        // L'envoi est déclenché de façon synchrone : au retour, le drapeau a été
        // consommé — sauf si la validation HTML5 a bloqué l'envoi, auquel cas on le
        // désarme pour ne pas sauter la vérification suivante.
        bypassCheck = true;
        if (remote) {
          Rails.fire(form, 'submit');
        } else if (form.requestSubmit) {
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

  // Un formulaire remote ne recharge pas la page : c'est à nous de recaler la
  // référence après chaque enregistrement. Ailleurs, le rechargement rejoue init() et
  // s'en charge. Le compteur n'est décrémenté qu'une fois la nouvelle référence en
  // main, pour ne pas laisser de fenêtre où l'on comparerait encore à l'ancienne.
  var watchOwnSaves = function(form) {
    $(form).on('ajax:send', function(event) {
      if (event.target !== form) return;
      savesInFlight += 1;
    });

    $(form).on('ajax:complete', function(event) {
      if (event.target !== form) return;
      refreshBaseline().always(function() {
        // Un envoi annulé avant `ajax:send` passe quand même par `ajax:complete` :
        // on borne à zéro pour ne pas désarmer la suppression des faux positifs.
        savesInFlight = Math.max(0, savesInFlight - 1);
      });
    });
  };

  var init = function() {
    var $marker = $('.js-form-freshness').first();
    if ($marker.length === 0) return;

    var form = $marker.closest('form')[0];
    if (!form) return;

    url = $marker.data('url');
    if (!url) return;

    refreshBaseline().then(function() {
      warnOnChange(form);
      blockStaleSubmit(form);
      watchOwnSaves(form);
    });
  };

  $(document).ready(init);

})(jQuery);
