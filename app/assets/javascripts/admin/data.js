(function($) {
  var init = function() {
    var $groups = $('#groups_');

    $('.data-filter-row').mouseleave(
      () => {
        if ($groups.select2('data').map((item)=> item.text).includes('Sans cohorte')) {
            $groups.val('Sans cohorte').trigger('change');
          }
      }
    )
  };

  $(document).ready(init);

})(jQuery);
