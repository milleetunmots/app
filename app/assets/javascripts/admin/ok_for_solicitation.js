// Cadre rouge de « OK pour sollicitation ? » mis à jour pendant la saisie : un texte sensible est
// tapé et le menu est vide. Le serveur pose la classe au chargement ; ici on la suit en direct.
$(document).ready(function() {
  let $sensitiveInformation = $('#child_support_sensitive_information');
  let $okForSolicitation = $('.ok-for-solicitation');
  let $select = $okForSolicitation.find('select');

  if (!$sensitiveInformation.length || !$select.length) return;

  function refreshAlert() {
    let alert = $sensitiveInformation.val().trim() !== '' && $select.val() === '';
    $okForSolicitation.toggleClass('sensitive-information-alert', alert);
  }

  $sensitiveInformation.on('input', refreshAlert);
  $select.on('change', refreshAlert);
});
