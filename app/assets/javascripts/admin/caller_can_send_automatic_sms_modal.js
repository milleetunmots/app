$(document).ready(function() {
  let $modal = $('#can-send-automatic-sms-validation');
  let $openButton = $('#toggle-automatic-sms-button');
  let $closeButton = $('.close');
  let $cancelButton = $('#modal-cancel-button');

  $openButton.on('click', function() {
    $modal.show();
  });

  $closeButton.on('click', function() {
    $modal.hide();
  });

  $cancelButton.on('click', function() {
    $modal.hide();
  });
});
