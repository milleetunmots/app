(function($) {

  var DATA_KEY = 'data-select2';

  var initSelect = function(input) {
    var $input = $(input);
    var options = JSON.parse($input.attr(DATA_KEY));
    $input.removeAttr(DATA_KEY).select2(options);
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
