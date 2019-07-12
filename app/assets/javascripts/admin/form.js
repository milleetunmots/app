(function($) {

  var initForm = function(form) {
    $(form).find('input, textarea, select').change(function() {
      Rails.fire(form, 'submit');
    });
  };

  var init = function() {
    $('form[data-remote="true"]').each(function() {
      initForm(this);
    });
  };

  $(document).ready(init);

})(jQuery);

