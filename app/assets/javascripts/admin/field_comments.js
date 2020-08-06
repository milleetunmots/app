(function($) {

  var createFieldComment = function(postUrl, content, successMessage, errorMessage) {
    var data = {
      content: content
    };
    var jqxhr = $.ajax({
      type: 'POST',
      url: postUrl,
      data: data,
      success: function() {
        toastr.success(successMessage);
        history.go(0);
      },
      error: function(jqXHR, textStatus, errorThrown) {
        toastr.error(errorThrown, errorMessage);
      }
    });
  };

  var openFieldCommentForm = function(postUrl, promptMessage, successMessage, errorMessage) {
    var content = prompt(promptMessage);

    if (content != null) {
      createFieldComment(postUrl, content, successMessage, errorMessage);
    }
  };

  var onClick = function(e) {
    e.preventDefault();

    var postUrl = $(this).attr('href');
    var promptMessage = $(this).data('prompt');
    var successMessage = $(this).data('success');
    var errorMessage = $(this).data('error');
    openFieldCommentForm(postUrl, promptMessage, successMessage, errorMessage);

    return false;
  };

  var init = function() {
    $(document).on('click', 'a.quick-field-comment-btn', onClick);
  };

  init();

})(jQuery);
