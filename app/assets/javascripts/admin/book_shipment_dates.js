(function($) {

  var csrfToken = function() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  };

  var init = function() {
    var $banner = $('.book-shipment-dates-banner');
    if (!$banner.length) return;

    var upsertUrl = $banner.data('upsertUrl');

    $banner.find('.book-shipment-date-input').each(function() {
      var $input = $(this);
      $input.on('click', function() { try { this.showPicker(); } catch(e) {} });
      $input.on('keydown', function(e) { e.preventDefault(); });
    });

    $banner.find('.book-shipment-date-save').on('click', function(event) {
      event.preventDefault();

      var $field = $(this).closest('.book-shipment-date-field');
      var $input = $field.find('.book-shipment-date-input');

      if (!$input.val()) return;

      $.ajax({
        url: upsertUrl,
        type: 'POST',
        dataType: 'json',
        headers: { 'X-CSRF-Token': csrfToken() },
        data: {
          id: $field.data('id'),
          date: $input.val()
        }
      }).done(function(response) {
        $field.data('id', response.id);
        toastr.success('Date de renvoi SAV mise à jour');
      }).fail(function(xhr) {
        var errors = (xhr.responseJSON && xhr.responseJSON.errors) || ['Erreur'];
        toastr.error(errors.join(', '));
      });
    });
  };

  $(document).ready(init);

})(jQuery);