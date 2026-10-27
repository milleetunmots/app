// Simulation de connexion (« Se connecter en tant que ») : l'admin est en lecture seule.
// Le serveur refuse déjà toute écriture ; on désactive ici les champs des formulaires
// qui écrivent. Désactiver le bouton ne suffirait pas : la fiche de suivi s'enregistre
// à chaque changement de champ (form.js). Un champ désactivé ne déclenche ni `change`
// ni le garde beforeunload des modifications non enregistrées.
$(document).ready(function() {
  if (!$('body').hasClass('impersonating')) return;

  var READ_ONLY_MESSAGE = 'Lecture seule pendant la simulation de connexion';
  // « Quitter la simulation » est un lien data-method : les UJS l'envoient par un formulaire
  // créé à la volée, qu'il ne faut pas arrêter.
  var exitPath = $('.impersonation-banner').data('exit-path');
  var isWritingForm = function(form) {
    if (new URL(form.action, window.location.href).pathname === exitPath) return false;

    return (form.getAttribute('method') || 'get').toLowerCase() !== 'get';
  };

  $('form').filter(function() { return isWritingForm(this); })
    .find('input:not([type=hidden]), select, textarea, button')
    .prop('disabled', true)
    .attr('title', READ_ONLY_MESSAGE);

  // Des scripts ajoutent ou réactivent des champs après coup : l'envoi est donc aussi
  // arrêté en phase de capture, avant rails-ujs et jquery_ujs qui écoutent tous deux
  // en bouillonnement sur le document.
  document.addEventListener('submit', function(event) {
    if (!isWritingForm(event.target)) return;

    event.preventDefault();
    event.stopImmediatePropagation();
    toastr.error(READ_ONLY_MESSAGE);
  }, true);

  var notifyRefusal = function(xhr) {
    if (!xhr || xhr.status !== 403) return;

    try {
      var body = JSON.parse(xhr.responseText);
      if (body.impersonation) toastr.error(body.error);
    } catch (e) {
      // Un 403 qui ne vient pas de la simulation garde son traitement habituel
    }
  };

  $(document).ajaxError(function(_event, jqXHR) { notifyRefusal(jqXHR); });
  document.addEventListener('ajax:error', function(event) {
    notifyRefusal(event.detail && event.detail[2]);
  });
});
