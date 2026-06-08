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

  var setStatus = function($container, text, color) {
    var $status = $container.find('.call-session-override-status');
    if (!$status.length) return;
    $status.text(text).css('color', color);
  };

  var updateResetVisibility = function($container) {
    var $start = $container.find('.call-session-override-start');
    var $end = $container.find('.call-session-override-end');
    var $reset = $container.find('.reset-call-session-override');
    if (!$reset.length) return;
    var differs = $start.val() !== $container.data('sessionStart') || $end.val() !== $container.data('sessionEnd');
    $reset.toggle(differs);
  };

  var formatFr = function(date) {
    var dd = ('0' + date.getUTCDate()).slice(-2);
    var mm = ('0' + (date.getUTCMonth() + 1)).slice(-2);
    return dd + '/' + mm + '/' + date.getUTCFullYear();
  };

  var updateSmsDate = function($container) {
    var $sms = $container.closest('tr').find('.call-session-override-sms-date');
    if (!$sms.length) return;
    var startVal = $container.find('.call-session-override-start').val();
    if (!startVal) { $sms.text(''); return; }
    var parts = startVal.split('-');
    var d = new Date(Date.UTC(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10)));
    d.setUTCDate(d.getUTCDate() - 3);
    $sms.text(formatFr(d));
  };

  var persistOverride = function($container, upsertUrl) {
    var $start = $container.find('.call-session-override-start');
    var $end = $container.find('.call-session-override-end');
    if (!$start.val() || !$end.val()) return;

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
      $container.find('.reset-call-session-override').css('color', PERSISTED_COLOR);
      setBorder($container, true);
      toastr.success('Enregistré');
    }).fail(function(xhr) {
      var errors = (xhr.responseJSON && xhr.responseJSON.errors) || ['Erreur'];
      setStatus($container, errors.join(', '), ERROR_COLOR);
      toastr.error(errors.join(', '));
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
    updateSmsDate($container);
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
      toastr.success('Réinitialisé');
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

      $start.on('keydown', function(e) { e.preventDefault(); });
      $start.on('change', function() {
        $end.attr('min', $start.val());
        $end.attr('max', $end.val());
        updateResetVisibility($container);
        updateSmsDate($container);
        persistOverride($container, upsertUrl);
      });

      $end.on('keydown', function(e) { e.preventDefault(); });
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
