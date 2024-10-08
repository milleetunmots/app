$(document).ready(function() {

  $('#workshop-parent-select').select2({
    placeholder: "Sélectionnez les parents",
    allowClear: true,
    ajax: {
      url: '/admin/children/parents',
      dataType: 'json',
      delay: 250
    },
    minimumInputLength: 3,
    multiple: true
  });

  // $('#workshop_parent_ids').select2({
  //   multiple: true
  // })

  $('#workshop-parent-select').on('change', function() {
    var values = $(this).val().filter(function(value) {
      return value !== '';
    });
    $(this).val(values)
    $('#workshop_parent_ids').val(values)
  });
});
