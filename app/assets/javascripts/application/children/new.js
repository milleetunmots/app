(function($) {

  var onToggleTerms = function() {
    var hasAccepted = $(this).is(':checked');
    $('.accepted-fields').toggle(hasAccepted);
  };

  var onChangeRegistrationSource = function() {
    var isEmpty = !$(this).val();
    $('#child-registration-source-details-field').toggle(!isEmpty);
  };

  var init = function() {
    onToggleTerms.apply($('input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]')[0]);
    $(document).on('change', 'input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]', onToggleTerms);

    onChangeRegistrationSource.apply($('select[name="child[registration_source]"]')[0]);
    $(document).on('change', 'select[name="child[registration_source]"]', onChangeRegistrationSource);
  };

  $(document).ready(init);

})(jQuery);
