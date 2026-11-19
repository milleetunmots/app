(function($) {

  // Champs qu'ActiveAdmin et select2 génèrent sans étiquette : ils sont nommés pour les
  // lecteurs d'écran

  var labelText = function($input) {
    return $input.closest('.input, .filter_form_field').find('label').first().text().trim();
  };

  // Cases de sélection des lignes d'une liste (actions groupées)
  var labelRowSelections = function() {
    $('input.toggle_all').not('[aria-label]').attr('aria-label', 'Sélectionner toutes les lignes');

    $('input.collection_selection').not('[aria-label]').each(function() {
      var id = $(this).closest('tr').find('.resource_id_link').first().text().trim();
      $(this).attr('aria-label', id ? 'Sélectionner la ligne ' + id : 'Sélectionner la ligne');
    });
  };

  // Filtres : l'étiquette n'est reliée ni aux champs d'une plage de dates, ni au menu du
  // critère (« Contient », « Égal à »…) des filtres texte et nombre
  var labelFilters = function() {
    $('.filter_date_range input[type="text"]').not('[aria-label]').each(function() {
      var bound = (this.placeholder || '').trim().toLowerCase();
      var label = labelText($(this));
      $(this).attr('aria-label', bound ? label + ' : ' + bound : label);
    });

    $('.select_and_search select').not('[aria-label]').each(function() {
      $(this).attr('aria-label', labelText($(this)) + ' : critère');
    });
  };

  var labelPagination = function() {
    $('.pagination_per_page select').not('[aria-label]').attr('aria-label', 'Nombre de lignes par page');
  };

  // Menus select2 à choix multiple : le champ de saisie reprend l'étiquette du menu.
  // select2 le recrée à chaque sélection, d'où le nouvel appel à chaque changement.
  var labelSelect2Search = function(select) {
    var $select = $(select);
    var label = $select.attr('id') && $('label[for="' + $select.attr('id') + '"]').first().text().trim();
    if (!label) label = labelText($select);
    if (!label) return;

    $select.next('.select2-container').find('.select2-search__field').attr('aria-label', label);
  };

  $(document).ready(function() {
    labelRowSelections();
    labelFilters();
    labelPagination();

    // Après les autres initialisations : les menus select2 sont créés par admin/select2.js,
    // chargé après ce fichier
    setTimeout(function() {
      $('select.select2-hidden-accessible[multiple]').each(function() { labelSelect2Search(this); });
    }, 0);
  });

  $(document).on('change', 'select.select2-hidden-accessible[multiple]', function() {
    labelSelect2Search(this);
  });

})(jQuery);
