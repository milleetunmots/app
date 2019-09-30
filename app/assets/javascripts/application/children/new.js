(function($) {

  var onToggleNoParent2 = function() {
    console.log('toggle noParent2');
  };

  var init = function() {
    console.log('init new children')
    $(document).on('change', 'input#noParent2', onToggleNoParent2);
  };

  init();

})(jQuery);
