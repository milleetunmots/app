// Bascule entre la vue lecture (blocs cliquables) et la vue édition (select2)
// des modules disponibles, sur la fiche de suivi. Les deux vues vivent dans le
// même formulaire : seule leur visibilité change, la soumission est inchangée.
(function($) {

  var HIDDEN_CLASS = 'initially-hidden';

  var setLabel = function($toggle, editing) {
    var readLabel = $toggle.data('read-label');
    var editLabel = $toggle.data('edit-label');

    $toggle.text(editing ? readLabel : editLabel);
  };

  $(document).on('click', '.support-module-edit-toggle', function(event) {
    event.preventDefault();

    var $toggle = $(this);
    var $blocks = $($toggle.data('blocks'));
    var $input = $($toggle.data('input'));
    var editing = $input.hasClass(HIDDEN_CLASS);

    $input.toggleClass(HIDDEN_CLASS, !editing);
    $blocks.toggleClass(HIDDEN_CLASS, editing);
    setLabel($toggle, editing);
  });

  // Les blocs sont rendus côté serveur : après une modification du select ils
  // ne reflètent plus la sélection tant que la fiche n'est pas enregistrée
  $(document).ready(function() {
    $('.support-module-edit-toggle').each(function() {
      var $toggle = $(this);

      $toggle.data('edit-label', $toggle.text());
      $($toggle.data('input')).find('select').on('change', function() {
        $($toggle.data('blocks')).find('.support-module-stale-notice').removeClass(HIDDEN_CLASS);
      });
    });
  });

})(jQuery);
