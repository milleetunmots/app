$(document).ready(function() {
  let $workshopInvitationScheduled = $('#workshop_invitation_scheduled');
  let $workshopScheduledInvitationDateInput = $('#workshop_scheduled_invitation_date_input');
  let $workshopScheduledInvitationTimeInput = $('#workshop_scheduled_invitation_time_input');
  let $workshopScheduledInvitationDate = $('#workshop_scheduled_invitation_date');
  let $workshopScheduledInvitationTime = $('#workshop_scheduled_invitation_time');
  let $workshopScheduledInvitationDateTime = $('#workshop_scheduled_invitation_date_time');
  let $workshopDate = $('#workshop_workshop_date');

  $workshopScheduledInvitationDateInput.hide();
  $workshopScheduledInvitationTimeInput.hide();
  $workshopInvitationScheduled.prop('checked', false);
  $workshopScheduledInvitationDateTime.val(new Date());

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

  $workshopInvitationScheduled.on('change', function() {
    let $workshopDateValue = undefined;
    if ($workshopDate.val()){
      $workshopDateValue = new Date($workshopDate.val());
    }
    if ($(this).is(':checked')) {
      if($workshopDateValue !== undefined) {
        $workshopScheduledInvitationDate.datepicker({minDate: new Date(), maxDate: new Date($workshopDateValue)});
        $workshopDateValue.setDate($workshopDateValue.getDate() - 7);
        $workshopScheduledInvitationDate.val(formatDate($workshopDateValue));
      }
      $workshopScheduledInvitationDateInput.show();
      $workshopScheduledInvitationTimeInput.show();
    } else {
      $workshopScheduledInvitationDateInput.hide();
      $workshopScheduledInvitationTimeInput.hide();
      $workshopScheduledInvitationDateTime.val(new Date());
    }
  });

  $workshopScheduledInvitationDateInput.on('change', function() {
    $workshopScheduledInvitationDate.val(formatDate(new Date($workshopScheduledInvitationDate.val())));
    $workshopScheduledInvitationDateTime.val(new Date($workshopScheduledInvitationDate.val() + ' ' + $workshopScheduledInvitationTime.val())); 
  });

  $workshopScheduledInvitationTimeInput.on('change', function() {
    $workshopScheduledInvitationDateTime.val(new Date($workshopScheduledInvitationDate.val() + ' ' + $workshopScheduledInvitationTime.val())); 
  });

  function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
});
