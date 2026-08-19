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
          position: $field.data('position'),
          date: $input.val()
        }
      }).done(function(response) {
        $field.data('id', response.id);

        if (response.following) {
          var $following = $banner.find('.book-shipment-date-field').eq(1);
          $following.data('id', response.following.id);
          $following.find('.book-shipment-date-input').val(response.following.date);
        }

        toastr.success(response.following ? 'Dates de renvoi SAV mises à jour' : 'Date de renvoi SAV mise à jour');
        if (response.warning) toastr.warning(response.warning);
      }).fail(function(xhr) {
        var errors = (xhr.responseJSON && xhr.responseJSON.errors) || ['Erreur'];
        toastr.error(errors.join(', '));
      });
    });
  };

  $(document).ready(init);

})(jQuery);