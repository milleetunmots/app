(function($) {

  var PERSISTED_BORDER = '4px solid #46be8a';
  var PERSISTED_COLOR = '#46be8a';
  var DEFAULT_COLOR = '#5E6469';
  var ERROR_COLOR = '#dc4747';

  var csrfToken = function() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  };

  var setBorder = function($container, persisted) {
    var $cell = $container.closest('tr').find('.call-session-override-border');
    if (!$cell.length || $cell.data('urgent') === true) return;
    $cell.css('border-left', persisted ? PERSISTED_BORDER : '');
  };

  var setStatus = function($container, text, color, timeout) {
    var $status = $container.find('.call-session-override-status');
    if (!$status.length) return;
    $status.text(text).css('color', color || '#888');
    if (text && timeout) {
      if(timeout) {
        clearTimeout($status.data('hideTimeout'));
        $status.data('hideTimeout', setTimeout(function() { $status.text(''); }, 2000));
      }
    }
  };

  var updateResetVisibility = function($container) {
    var $start = $container.find('.call-session-override-start');
    var $end = $container.find('.call-session-override-end');
    var $reset = $container.find('.reset-call-session-override');
    if (!$reset.length) return;
    var differs = $start.val() !== $container.data('sessionStart') || $end.val() !== $container.data('sessionEnd');
    $reset.toggle(differs);
  };

  var persistOverride = function($container, upsertUrl) {
    var $start = $container.find('.call-session-override-start');
    var $end = $container.find('.call-session-override-end');
    if (!$start.val() || !$end.val()) return;

    setStatus($container, 'Enregistrement…');
    $.ajax({
      url: upsertUrl,
      type: 'POST',
      dataType: 'json',
      headers: { 'X-CSRF-Token': csrfToken() },
      data: {
        group_id: $container.data('groupId'),
        call_session: $container.data('callSession'),
        start_date: $start.val(),
        end_date: $end.val()
      }
    }).done(function() {
      setStatus($container, 'Enregistré', PERSISTED_COLOR, true);
      $container.find('.reset-call-session-override').css('color', PERSISTED_COLOR);
      setBorder($container, true);
    }).fail(function(xhr) {
      var errors = (xhr.responseJSON && xhr.responseJSON.errors) || ['Erreur'];
      setStatus($container, errors.join(', '), ERROR_COLOR);
    });
  };

  var resetOverride = function($container, resetUrl) {
    var $start = $container.find('.call-session-override-start');
    var $end = $container.find('.call-session-override-end');
    var sessionStart = $container.data('sessionStart');
    var sessionEnd = $container.data('sessionEnd');

    $start.val(sessionStart).attr('max', sessionEnd);
    $end.val(sessionEnd).attr('min', sessionStart);
    updateResetVisibility($container);

    setStatus($container, 'Réinitialisation…');
    $.ajax({
      url: resetUrl,
      type: 'DELETE',
      dataType: 'json',
      headers: { 'X-CSRF-Token': csrfToken() },
      data: {
        group_id: $container.data('groupId'),
        call_session: $container.data('callSession')
      }
    }).done(function() {
      setStatus($container, 'Réinitialisé', PERSISTED_COLOR, true);
      $container.find('.reset-call-session-override').css('color', DEFAULT_COLOR);
      setBorder($container, false);
    }).fail(function() {
      setStatus($container, 'Erreur', ERROR_COLOR);
    });
  };

  var init = function() {
    var $panel = $('.call-session-date-overrides-panel');
    if (!$panel.length) return;

    var upsertUrl = $panel.data('upsertUrl');
    var resetUrl = $panel.data('resetUrl');

    $panel.find('.call-session-override-range').each(function() {
      var $container = $(this);
      var $start = $container.find('.call-session-override-start');
      var $end = $container.find('.call-session-override-end');
      var $reset = $container.find('.reset-call-session-override');

      $start.on('change', function() {
        $end.attr('min', $start.val());
        $end.attr('max', $end.val());
        updateResetVisibility($container);
        persistOverride($container, upsertUrl);
      });

      $end.on('change', function() {
        $start.attr('min', $start.val());
        $start.attr('max', $end.val());
        updateResetVisibility($container);
        persistOverride($container, upsertUrl);
      });

      $reset.on('click', function(event) {
        event.preventDefault();
        resetOverride($container, resetUrl);
      });
    });
  };

  $(document).ready(init);

})(jQuery);
