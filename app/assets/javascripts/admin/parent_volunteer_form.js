$(document).ready(function() {
    let radios = $(".parent-volunteer-reason-radio");
    let isParentSelectFieldPresent = $('#select-parent-volunteer').length === 1
    let checkboxes = $('.select-parent');
    let validation = $("#parent_volunteer-form-submit");
    let form_details = $('#parent-volunteer-form-details');
    form_details.hide();
    validation.prop('disabled', true);

    radios.change(function() {
        if (isParentSelectFieldPresent) {
            validation.prop('disabled', !($('#select-parent-1').is(':checked') || $('#select-parent-2').is(':checked')));
        } else {
            validation.prop('disabled', false);
        }
        if ($(this).val() === 'parent') {
            form_details.show();
        } else {
            form_details.hide();
        }
    });

    checkboxes.change(function() {
        let selectedRadioValue = $('input[name="reason"]:checked').val();
        if (selectedRadioValue == undefined) {
            validation.prop('disabled', true);
        } else {
            if ($('#select-parent-1').is(':checked') || $('#select-parent-2').is(':checked')) {
                validation.prop('disabled', false);
            } else {
                validation.prop('disabled', true);
            }
        }
    });
});
