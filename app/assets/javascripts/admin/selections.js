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

  $('#registration_sources').select2({
    width: '100%',
    placeholder: "Choisissez les origines des inscriptions",
    data: [
        {
          "id": "caf",
          "text": "CAF"
        },
        {
          "id": "pmi",
          "text": "Mon/ma professionnel·le de santé"
        },
        {
          "id": "friends",
          "text": "Par des amis / de la famille"
        },
        {
          "id": "therapist",
          "text": "Mon orthophoniste"
        },
        {
          "id": "nursery",
          "text": "Crèche"
        },
        {
          "id": "resubscribing",
          "text": "J'ai déjà reçu les SMS et je réinscris un enfant"
        },
        {
          "id": "other",
          "text": "Autre"
        }
      ]
  });

  $('#age_ranges').select2({
    width: '100%',
    placeholder: "Choisissez les tranches d'âge",
    data: [
      {
        "id": 6,
        "text": "Moins de 6 mois"
      },
      {
        "id": 12,
        "text": "12 - 24 mois"
      },
      {
        "id": 24,
        "text": "24 - 36 mois"
      },
      {
        "id": 36,
        "text": "Plus de 36 mois"
      },
    ]
  })

});
