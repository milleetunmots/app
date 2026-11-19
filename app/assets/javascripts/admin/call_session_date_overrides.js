(function($) {

  // L'état de chaque ligne passe par des classes : les couleurs restent dans
  // app/assets/stylesheets/admin/call_session_date_overrides.sass

  var csrfToken = function() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  };

  var setBorder = function($container, persisted) {
    var $row = $container.closest('tr');
    var $cell = $row.find('.call-session-override-border');
    if (!$cell.length) return;

    $cell.toggleClass('call-session-override-border--persisted', persisted);
    $cell.toggleClass('call-session-override-border--alert', !persisted && $cell.data('alert') === true);
  };

  var setDeadlineDateColor = function($container, persisted) {
    var $row = $container.closest('tr');
    var $deadline = $row.find('.call-session-override-modification-deadline');
    if (!$deadline.length) return;

    var $cell = $row.find('.call-session-override-border');
    if (!$cell.length) return;

    $deadline.toggleClass('call-session-override-modification-deadline--alert', !persisted && $cell.data('alert') === true);
  };

  var setError = function($container, text) {
    var $status = $container.find('.call-session-override-status');
    if (!$status.length) return;
    $status.text(text).addClass('call-session-override-status--error');
  };

  var setResetPersisted = function($container, persisted) {
    $container.find('.reset-call-session-override').toggleClass('reset-call-session-override--persisted', persisted);
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
      setResetPersisted($container, true);
      setBorder($container, true);
      setDeadlineDateColor($container, true);
      toastr.success('Enregistré');
    }).fail(function(xhr) {
      var errors = (xhr.responseJSON && xhr.responseJSON.errors) || ['Erreur'];
      setError($container, errors.join(', '));
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
      setResetPersisted($container, false);
      setBorder($container, false);
      setDeadlineDateColor($container, false);
    }).fail(function() {
      setError($container, 'Erreur');
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

      $start.on('click', function() { try { this.showPicker(); } catch(e) {} });
      $start.on('keydown', function(e) { e.preventDefault(); });
      $start.on('change', function() {
        $end.attr('min', $start.val());
        $end.attr('max', $end.val());
        updateResetVisibility($container);
        updateSmsDate($container);
        persistOverride($container, upsertUrl);
      });

      $end.on('click', function() { try { this.showPicker(); } catch(e) {} });
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
