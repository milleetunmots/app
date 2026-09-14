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

  // L'aperçu suit la sélection locale, indépendamment de l'enregistrement automatique.
  // Une ancienne réponse ne doit pas remplacer une sélection plus récente.
  $(document).ready(function() {
    $('.support-module-edit-toggle').each(function() {
      var $toggle = $(this);
      var $blocks = $($toggle.data('blocks'));
      var revision = 0;
      var request;

      $toggle.data('edit-label', $toggle.text());
      $($toggle.data('input')).find('select').on('change', function() {
        var currentRevision = ++revision;
        if (request) request.abort();

        $blocks.empty().append($('<span>', {
          class: 'support-module-blocks-empty',
          text: 'Mise à jour de l’aperçu…'
        }));
        request = $.ajax({
          url: $toggle.data('preview-url'),
          data: { support_module_ids: $(this).val() || [] },
          dataType: 'html'
        }).done(function(html) {
          if (currentRevision !== revision) return;
          var $preview = $('<div>').append($.parseHTML(html));
          $blocks.empty().append($preview.find('.support-module-blocks').contents());
        }).fail(function(_xhr, status) {
          if (status === 'abort' || currentRevision !== revision) return;
          $blocks.empty().append($('<span>', {
            class: 'support-module-blocks-empty',
            text: 'L’aperçu est temporairement indisponible. Votre sélection reste visible en mode Modifier.'
          }));
        });
      });
    });
  });

})(jQuery);
