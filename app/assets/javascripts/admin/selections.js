$(document).ready(function() {
  var $parentId = $('#parent_id').val() || undefined
  var $supporterId = $('#supporter_id').val() || undefined

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

  if ($parentId === undefined) {
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
  } else {
    let newOptions = { tags: true, data: [], width: '100%'};
    let $recipients = $('#recipients');
    $.ajax({
      type: 'GET',
      url: '/admin/message/recipients?parent_id='+$parentId
    }).done(function(data) {
      newOptions.data = data.results.map(item => {
        return { id: item.id, text: item.name }
      })
      $recipients.select2(newOptions);
      $recipients.val('parent.'+$parentId);
      $recipients.trigger('change');
    });

    $('#redirection_target').select2({
      width: '100%',
      placeholder: "Choisissez une url cible",
      allowClear: true,
      ajax: {
        url: '/admin/message/redirection_targets?parent_id='+$parentId,
        dataType: 'json',
        delay: 250,
      },
    });
  }

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

  $('#call_goals_sms').select2({
    width: "100%"
  });

  if ($supporterId === undefined) {
    $('#supporter').select2({
      width: '100%',
      placeholder: "Limitez l'envoi du message aux enfants sous sa responsabilité dans la cohorte choisie",
      allowClear: true,
      ajax: {
        url: '/admin/message/supporter',
        dataType: 'json',
        delay: 250
      },
    });
  } else {
    let $supporter = $('#supporter');
    let newOptions = {data: [], width: '100%'}
    $.ajax({
      type: 'GET',
      url: '/admin/message/supporter?supporter_id='+$supporterId
    }).done(function(data) {
      newOptions.data = data.results
      $supporter.select2(newOptions);
      $supporter.val($supporterId);
      $supporter.trigger('change');
    });
  }
});
