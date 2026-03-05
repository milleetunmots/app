(function($) {

  var toggleCtaTitleField = function(idx) {
    var $linkSelect = $('[data-cta-link-index="' + idx + '"]');
    var $ctaWrapper = $('[data-cta-title-index="' + idx + '"]');

    if ($linkSelect.val()) {
      $ctaWrapper.show();
    } else {
      $ctaWrapper.find('input').val('');
      $ctaWrapper.hide();
    }
  };

  var init = function() {
    if ($('[data-cta-link-index]').length === 0) return;

    [1, 2, 3].forEach(function(idx) {
      toggleCtaTitleField(idx);
      $('[data-cta-link-index="' + idx + '"]').on('change', function() {
        toggleCtaTitleField(idx);
      });
    });
  };

  $(document).ready(init);

})(jQuery);
