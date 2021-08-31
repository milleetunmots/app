$(document).ready(function() {
  $('#module_to_send').select2({
    width: '100%',
    placeholder: "Choisissez un module",
    allowClear: true,
    ajax: {
      url: '/admin/module/module_to_send',
      dataType: 'json',
      delay: 250
    },
  });
});
