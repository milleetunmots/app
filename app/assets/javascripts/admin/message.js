$(document).ready(function() {

  var formatResult = function(result) {
    var $a = $('<div class="search-result search-result-'+(result.type || '').toLowerCase()+'">');

    $a.append('<i class="search-result-icon fas fa-'+result.icon+' fa-fw">');
    $a.append(result.html);

    return $a;
  }

  var formatSelection = function(selection) {
    var $a = $('<span>');

    $a.append('<i class="search-result-icon fas fa-'+selection.icon+' fa-fw">');
    $a.append(selection.name);

    return $a;
  }

  $('#recipients').select2({
    width: '100%',
    placeholder: "Entrez le nom d'une cohorte, d'un tag ou d'un parent directement",
    ajax: {
      url: '/admin/message/recipients',
      dataType: 'json',
      delay: 250
    },
    templateResult: formatResult,
    templateSelection: formatSelection,
    minimumInputLength: 3
  });

  //  Cible url

  function templateResultUrl (state) {
    var $a = $('<span>');
    $a.append(state.name);

    return $a;
  };

  var formatSelectionUrl = function(selection) {
    var $a = $('<span>');
    $a.append(selection.name);
    return $a;
  }

  $('#url_cible').select2({
    width: '100%',
    placeholder: "Choisissez une url cible",
    ajax: {
      url: '/admin/message/url_cible',
      dataType: 'json',
      delay: 250
    },
    templateSelection: formatSelectionUrl,
    templateResult: templateResultUrl
  });
  
});
