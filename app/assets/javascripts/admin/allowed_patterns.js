// Le match_type dépend du kind (AllowedPattern::MATCH_TYPES_BY_KIND), mais le kind
// se choisit côté client : le select est rendu avec toutes les options, chacune
// étiquetée data-kinds, et on ne garde ici que celles du kind sélectionné. Sans ça,
// un match_type invalide pour le kind resterait sélectionnable et ne serait refusé
// qu'au submit.
$(document).ready(function() {
  var $kind = $('#allowed_pattern_kind');
  var $matchType = $('#allowed_pattern_match_type');

  if ($kind.length === 0 || $matchType.length === 0) { return; }

  var $allOptions = $matchType.find('option');

  // Le format attendu pour `value` dépend du couple (kind, match_type) : le hint
  // du champ est rendu avec celui de la sélection initiale, et tous les autres
  // sont exposés en data-hints (cf. ActiveAdmin::AllowedPatternsHelper).
  var $hint = $('#allowed_pattern_value_input .inline-hints');
  var hints = $('#allowed_pattern_value').data('hints') || {};

  var refreshHint = function() {
    if ($hint.length === 0) { return; }

    var hint = hints[`${$kind.val()}/${$matchType.val()}`];
    if (hint) { $hint.text(hint); }
  };

  var refreshMatchTypes = function() {
    var kind = $kind.val();
    var previousValue = $matchType.val();
    var $options = $allOptions.filter(function() {
      return ($(this).attr('data-kinds') || '').split(' ').indexOf(kind) !== -1;
    });

    // On retire puis on réinsère plutôt que de masquer : `hidden` sur une <option>
    // est ignoré par certains navigateurs, et l'option resterait atteignable au
    // clavier. Le detach() conserve les options pour les prochains changements.
    $allOptions.detach();
    $matchType.append($options);

    // Réinsérer les options réinitialise la sélection du navigateur : on remet la
    // valeur précédente si elle vaut toujours pour ce kind (cas de l'édition d'un
    // pattern existant), sinon la première option valide.
    var values = $options.map(function() { return this.value; }).get();
    $matchType.val(values.indexOf(previousValue) === -1 ? values[0] : previousValue);

    // Changer de kind peut réaffecter le match_type : le hint doit suivre ce
    // nouveau couple, pas seulement le kind.
    refreshHint();
  };

  $kind.on('change', refreshMatchTypes);
  $matchType.on('change', refreshHint);
  refreshMatchTypes();
});
