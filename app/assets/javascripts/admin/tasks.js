(function($) {

  var createTask = function(postUrl, title, successMessage, errorMessage) {
    var data = {
      title: title
    };
    var jqxhr = $.ajax({
      type: 'POST',
      url: postUrl,
      data: data,
      success: function() {
        toastr.success(successMessage);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        toastr.error(errorThrown, errorMessage);
      }
    });
  };

  var openTaskForm = function(postUrl, promptMessage, successMessage, errorMessage) {
    var title = prompt(promptMessage);

    if (title != null) {
      createTask(postUrl, title, successMessage, errorMessage);
    }
  };

  var onClick = function(e) {
    e.preventDefault();

    var postUrl = $(this).attr('href');
    var promptMessage = $(this).data('prompt');
    var successMessage = $(this).data('success');
    var errorMessage = $(this).data('error');
    openTaskForm(postUrl, promptMessage, successMessage, errorMessage);

    return false;
  }

  var init = function() {
    $(document).on('click', 'a.quick-task-btn', onClick);
  };

  init();

})(jQuery);
