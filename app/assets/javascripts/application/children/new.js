(function($) {

  var onToggleNoParent2 = function() {
    var isAbsent = $(this).is(':checked');
    $('#parent2-fields').toggle(!isAbsent);
  };

  var init = function() {
    onToggleNoParent2.apply($('input[type="checkbox"][name="child[parent2_absent]"]')[0]);
    $(document).on('change', 'input[type="checkbox"][name="child[parent2_absent]"]', onToggleNoParent2);
  };

  $(document).ready(init);

})(jQuery);
