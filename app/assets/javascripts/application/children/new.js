(function($) {

  var onToggleTerms = function() {
    var hasAccepted = $(this).is(':checked');
    $('.accepted-fields').toggleClass('hidden', !hasAccepted);
  };

  var onChangeRegistrationSource = function() {
    var isEmpty = !$(this).val();
    $('#child-registration-source-details-field').toggle(!isEmpty);
  };

  var initAddChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $fields.detach();

    $btn.click(function(e) {
      e.preventDefault();
      $container.append($fields);
      $container.removeClass('hidden');
      // only show latest rm btn
      $('.child-fields-container .btn.rm-child-btn').hide();
      $container.find('.btn.rm-child-btn').show();
      return false;
    })
  }

  var initRmChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $btn.click(function(e) {
      e.preventDefault();
      $container.addClass('hidden');
      $fields.detach();
      // re-show previous rm btn, if any
      $('.child-fields-container .btn.rm-child-btn').last().show();
      return false;
    })
  };

  var init = function() {
    onToggleTerms.apply($('input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]')[0]);
    $(document).on('change', 'input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]', onToggleTerms);

    onChangeRegistrationSource.apply($('select[name="child[registration_source]"]')[0]);
    $(document).on('change', 'select[name="child[registration_source]"]', onChangeRegistrationSource);

    $('.child-fields-container.hidden .btn.rm-child-btn').each(function() {
      initRmChildBtn(this);
    });
    $('.child-fields-container.hidden .btn.add-child-btn').each(function() {
      initAddChildBtn(this);
    });
  };

  $(document).ready(init);

})(jQuery);
