(function($) {

  var DATA_KEY = 'data-chars-counter';

  var countChars = function($input) {
    return $input.val().length;
  };

  var updateCounter = function($counter, value, max) {
    $counter.html(
      [
        value,
        '/',
        max,
        '(' + Math.ceil(value / max) + ')'
      ].join(' ')
    );
  };

  var initInput = function(input) {
    var $input = $(input);
    var chars = $input.attr(DATA_KEY);

    var $counter = $('<p class="inline-hints">');

    $input.after($counter);

    var update = function() {
      setTimeout(function() {
        updateCounter(
          $counter,
          countChars($input),
          chars
        );
      }, 100);
    };

    update();
    $input.on('keydown', update);
  };

  var init = function() {
    $('['+DATA_KEY+']').each(function() {
      initInput(this);
    });
  };

  $(document).ready(init);

})(jQuery);
