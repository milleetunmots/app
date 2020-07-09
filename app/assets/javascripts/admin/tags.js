(function($) {

  var shouldFixHeadBug = function() {
    return $('body.active_admin.admin_tags.show').length + $('body.active_admin.admin_tags.edit').length > 0;
  };

  var fixHeadBug = function() {
    console.log('Fix temporary AA bug with tags');
    $('body').children().first()[0].previousSibling.remove();
  };

  var init = function() {
    if( shouldFixHeadBug() ) {
      fixHeadBug();
    }
  };

  $(document).ready(init);

})(jQuery);
