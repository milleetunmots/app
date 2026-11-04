// Menu déroulant de l'avatar, ouvert au clic (arctic_admin ne gère pas les sous-menus de #utility_nav).
// Seules les accompagnantes ont des entrées : pour les autres rôles le lien de l'avatar reste un lien direct.
(function($) {
  var MENU = '#utility_nav #current_user.has_nested';

  var hasEntries = function($menu) {
    return $menu.find('> ul.menu > li').length > 0;
  };

  var setOpen = function($menu, open) {
    $menu.toggleClass('open', open);
    $menu.children('a').attr('aria-expanded', open ? 'true' : 'false');
  };

  var closeAll = function() {
    $(MENU).each(function() { setOpen($(this), false); });
  };

  $(document).on('click', MENU + ' > a', function(event) {
    var $menu = $(this).parent();
    if (!hasEntries($menu)) { return; }

    event.preventDefault();
    setOpen($menu, !$menu.hasClass('open'));
  });

  $(document).on('click', function(event) {
    if ($(event.target).closest(MENU).length === 0) { closeAll(); }
  });

  $(document).on('keydown', function(event) {
    if (event.key === 'Escape') { closeAll(); }
  });

  $(document).ready(function() {
    $(MENU).each(function() {
      var $menu = $(this);
      if (hasEntries($menu)) {
        $menu.children('a').attr({ 'aria-haspopup': 'true', 'aria-expanded': 'false' });
      }
    });
  });
})(jQuery);
