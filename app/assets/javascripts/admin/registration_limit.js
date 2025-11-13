$(document).ready(function() {
  let $registrationLimitEndDateInput = $('#registration_limit_end_date_input');
  let $registrationLimitEndDate = $('#registration_limit_end_date')
  let $registrationLimitWithoutEndDate = $('#registration_limit_without_end_date');
  let registrationLimitEndDateValue = $('#registration_limit_end_date').val();

  $registrationLimitWithoutEndDate.prop('checked', registrationLimitEndDateValue === '');
  $registrationLimitEndDateInput.prop('hidden', registrationLimitEndDateValue === '');

  $registrationLimitWithoutEndDate.on('change', function() {
    $registrationLimitEndDate.val('');
    $registrationLimitEndDateInput.prop('hidden', $(this).is(':checked'));
  })
});
