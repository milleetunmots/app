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

  //  redirection_target

  $('#redirection_target').select2({
    width: '100%',
    placeholder: "Choisissez une url cible",
    allowClear: true,
    ajax: {
      url: '/admin/message/redirection_targets',
      dataType: 'json',
      delay: 250
    },
  });

  $('#image_to_send').select2({
    width: '100%',
    placeholder: "Choisissez une image",
    allowClear: true,
    ajax: {
      url: '/admin/message/image_to_send',
      dataType: 'json',
      delay: 250
    },
  });
});
