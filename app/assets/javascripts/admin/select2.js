(function($) {

  var DATA_KEY = 'data-select2';

  // For selects configured with closeOnSelect: false (multi-selects that stay open so
  // several options can be picked in a row), picking a result after typing a search
  // closes the dropdown, like the old single-pick UX did. Select2 already clears the
  // search field and resets the list whenever the dropdown closes, so nothing else is
  // needed there. Picking without searching (just browsing the open list) keeps the
  // dropdown open, so fast multi-picking is preserved.
  //
  // Note: for multiple selects, the search field lives on the "selection" adapter
  // (options.multiple decorates it with SelectionSearch), not on the dropdown adapter.
  var enableStayOpenBehavior = function($input) {
    $input.on('select2:select', function() {
      var instance = $input.data('select2');
      var $search = instance && instance.selection && instance.selection.$search;
      if ($search && $search.val()) {
        $input.select2('close');
      }
    });
  };

  var initSelect = function(input) {
    var $input = $(input);
    var options = JSON.parse($input.attr(DATA_KEY));
    $input.removeAttr(DATA_KEY).select2(options);

    if (options.closeOnSelect === false) {
      enableStayOpenBehavior($input);
    }
  };

  var init = function(obj) {
    $(obj || document).find('['+DATA_KEY+']').each(function() {
      initSelect(this);
    });
  };

  $(document).ready(init);

  $(document).on('has_many_add:after', function(_event, fieldset) {
    init(fieldset);
  });

})(jQuery);
