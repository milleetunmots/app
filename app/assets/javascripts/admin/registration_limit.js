$(document).ready(function() {
  let $registrationLimitEndDateInput = $('#registration_limit_end_date_input');
  let $registrationLimitEndDate = $('#registration_limit_end_date')
  let $registrationLimitWithoutEndDate = $('#registration_limit_without_end_date');

  $registrationLimitWithoutEndDate.prop('checked', true);
  $registrationLimitEndDateInput.prop('hidden', true);

  $registrationLimitWithoutEndDate.on('change', function() {
    $registrationLimitEndDate.val('');
    $registrationLimitEndDateInput.prop('hidden', $(this).is(':checked'));
  })
});
