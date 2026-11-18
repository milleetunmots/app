// Filtres des listes : « Filtrer » et « Supprimer les filtres » aussi en haut de la
// colonne, pour lancer un filtre sans faire défiler la longue liste des champs. Copie
// des boutons du bas sans leurs champs cachés (scope, tri), déjà envoyés par ceux-ci.
// ActiveAdmin écoute ces boutons par délégation (document) : la copie fonctionne telle
// quelle.
document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('#sidebar form.filter_form').forEach(function(form) {
    var buttons = form.querySelector('.buttons');
    if (!buttons) return;

    var topButtons = buttons.cloneNode(true);
    topButtons.classList.add('buttons--top');
    topButtons.querySelectorAll('input[type="hidden"]').forEach(function(input) {
      input.remove();
    });
    form.insertBefore(topButtons, form.firstChild);
  });
});
