(function($) {

  var insertElements = function(ol) {
    // console.log('[RADIO] insertElements', ol);

    $(ol).children('li.choice').each(function() {
      $(this).append($('<span class="unselect-btn">&#10060;</span>'));
      updateChoice(this);
    });
    var name = $(ol).find('input[type="radio"]').first().attr('name');
    $(ol).after($('<input type="radio" class="empty-choice" value=""/>').attr('name', name));
  };

  var unselect = function(li) {
    // console.log('[RADIO] unselect', li);

    var $li = $(li);
    $li.find('input[type="radio"]:checked').prop('checked', false);
    updateChoicesGroup($li.closest('ol.choices-group'));
    // trigger form callbacks (remote submit, for instance)
    $li.find('input[type="radio"]').change();
  };

  var updateChoicesGroup = function(ol) {
    // console.log('[RADIO] updateChoicesGroup', ol);

    var $ol = $(ol);
    var withChoice = $ol.find('input[type="radio"]:checked').length > 0;
    $ol.toggleClass(
      'with-choice',
      withChoice
    );
    $ol.next('.empty-choice').prop('checked', !withChoice);
    $ol.children('li.choice').each(function() {
      updateChoice(this);
    });
  };

  var updateChoice = function(li) {
    // console.log('[RADIO] updateChoice', li);

    var $li = $(li);
    $li.toggleClass(
      'chosen',
      $li.find('input[type="radio"]:checked').length > 0
    );
  };

  var init = function() {
    $('ol.choices-group').each(function() {
      insertElements(this);
      updateChoicesGroup(this);
    });
    $(document).on('click', 'ol.choices-group li.choice input[type="radio"]', function() {
      var $ol = $(this).closest('ol.choices-group');
      window.setTimeout(function() {
        updateChoicesGroup($ol[0]);
      }, 100);
    });
    $(document).on('click', 'ol.choices-group li.choice .unselect-btn', function() {
      unselect($(this).closest('li.choice'));
    });
  };

  $(document).ready(init);

})(jQuery);

