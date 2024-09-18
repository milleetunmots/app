$(document).ready(function() {
    let radios = $(".parent-volunteer-reason-radio");
    let isParentSelectFieldPresent = $('#select-parent-volunteer').length === 1
    let checkboxes = $('.select-parent');
    let validation = $("#parent_volunteer-form-submit");
    let form_details = $('#parent-volunteer-form-details');
    let selectParentVolunteerReason = $("#select-parent-volunteer-reason")
    form_details.hide();
    validation.prop('disabled', true);

    if (isParentSelectFieldPresent) {
        selectParentVolunteerReason.hide();
    }

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

        if (!$('#select-parent-1').is(':checked') && !$('#select-parent-2').is(':checked')) {
            selectParentVolunteerReason.hide();
        } else {
            selectParentVolunteerReason.show();
        }

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
