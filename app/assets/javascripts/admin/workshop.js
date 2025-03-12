$(document).ready(function() {
  let $workshopInvitationScheduled = $('#workshop_invitation_scheduled');
  let $workshopScheduledInvitationDateInput = $('#workshop_scheduled_invitation_date_input');
  let $workshopScheduledInvitationTimeInput = $('#workshop_scheduled_invitation_time_input');
  let $workshopScheduledInvitationDate = $('#workshop_scheduled_invitation_date');
  let $workshopScheduledInvitationTime = $('#workshop_scheduled_invitation_time');
  let $workshopScheduledInvitationDateTime = $('#workshop_scheduled_invitation_date_time');
  let $workshopDate = $('#workshop_workshop_date');

  $workshopInvitationScheduled.prop('disabled', true);
  $workshopInvitationScheduled.prop('checked', false);
  $workshopScheduledInvitationDateTime.val(null);
  hideDateTimeInputs();
  

  $('.workshop-parent-select').select2({
    placeholder: "Sélectionnez les parents",
    allowClear: true,
    ajax: {
      url: '/admin/workshops/search_eligible_parents',
      dataType: 'json',
      delay: 250
    },
    minimumInputLength: 3,
    multiple: true
  });

  $('.workshop-parent-select').on('change', function() {
    var values = $(this).val().filter(function(value) {
      return value !== '';
    });
    $(this).val(values)
    $('#workshop_parent_ids').val(values)
  });

  $workshopDate.on('change', function() {
    if ($workshopDate.val() === '') {
      $workshopInvitationScheduled.prop('disabled', true);
    } else {
      $workshopInvitationScheduled.prop('disabled', false);
    }
    if ($workshopInvitationScheduled.is(':checked')){
      alert("Attention, l'invitation n'est plus programmée pour plus tard ! Recochez la case si vous souhaitez programmer l'invitation pour plus tard.");
    }
    $workshopInvitationScheduled.prop('checked', false);
    $workshopInvitationScheduled.trigger('change');
  });

  $workshopInvitationScheduled.on('change', function() {
    if ($(this).is(':checked')) {
      $workshopScheduledInvitationDate.datepicker('destroy');
      $workshopScheduledInvitationDate.datepicker({minDate: new Date(), maxDate: new Date($workshopDate.val())});
      $workshopScheduledInvitationDate.val(formatDate(new Date()));
      $workshopScheduledInvitationDate.trigger('change');
      showDateTimeInputs();
    } else {
      hideDateTimeInputs();
      $workshopScheduledInvitationDateTime.val(null);
    }
  });

  $workshopScheduledInvitationDateInput.on('change', function() {
    $workshopScheduledInvitationDate.val(formatDate(new Date($workshopScheduledInvitationDate.val())));
    $workshopScheduledInvitationDateTime.val(new Date($workshopScheduledInvitationDate.val() + ' ' + $workshopScheduledInvitationTime.val())); 
  });

  $workshopScheduledInvitationTimeInput.on('change', function() {
    $workshopScheduledInvitationDateTime.val(new Date($workshopScheduledInvitationDate.val() + ' ' + $workshopScheduledInvitationTime.val())); 
  });

  function hideDateTimeInputs() {
    $workshopScheduledInvitationDateInput.hide();
    $workshopScheduledInvitationTimeInput.hide();
  }

  function showDateTimeInputs() {
    $workshopScheduledInvitationDateInput.show();
    $workshopScheduledInvitationTimeInput.show();
  }

  function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
});
