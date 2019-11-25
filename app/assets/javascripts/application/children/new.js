(function($) {

  var onToggleNoParent2 = function() {
    var isAbsent = $(this).is(':checked');
    $('#parent2-fields').toggle(!isAbsent);
  };

  var onChangeRegistrationSource = function() {
    var isEmpty = !$(this).val();
    $('#child-registration-source-details-field').toggle(!isEmpty);
  };

  var init = function() {
    onToggleNoParent2.apply($('input[type="checkbox"][name="child[parent2_absent]"]')[0]);
    $(document).on('change', 'input[type="checkbox"][name="child[parent2_absent]"]', onToggleNoParent2);

    onChangeRegistrationSource.apply($('select[name="child[registration_source]"]')[0]);
    $(document).on('change', 'select[name="child[registration_source]"]', onChangeRegistrationSource);
  };

  $(document).ready(init);

})(jQuery);
