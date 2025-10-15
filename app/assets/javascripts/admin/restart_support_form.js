$(document).ready(function(){
  let checkboxes = $(".restart-support-form-checkbox");
  let otherReasonCheckbox = $("input[value='other']");
  let confirmation = $("#restart-support-form-submit");
  let restartSupportDetails = $('#restart-support-details');
  let detailsTextarea = $('textarea[name="details"]');

  restartSupportDetails.hide();
  confirmation.prop('disabled', true);

  checkboxes.change(function() {
    let checkboxesChecked = $(".restart-support-form-checkbox:checked");

    restartSupportDetails.toggle(otherReasonCheckbox.is(':checked'));
    if(checkboxesChecked.is(otherReasonCheckbox)) {
      confirmation.prop('disabled', detailsTextarea.val().length === 0);
      detailsTextarea.on('input', function() {
        confirmation.prop('disabled', detailsTextarea.val().length === 0);
      });
    } else {
      confirmation.prop('disabled', false);
    }
  });
});
