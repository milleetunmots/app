(function($) {

  // Un seul menu déroulant ouvert à la fois. ActiveAdmin ferme ses menus à tout clic sur la
  // page, mais le bouton d'un menu arrête la propagation de son clic (return false) : ouvrir
  // un second menu laissait le premier ouvert. Écouté en phase de capture, le clic sur un
  // bouton ferme les autres menus avant que le bouton n'ouvre le sien.
  document.addEventListener('click', function(event) {
    var button = event.target.closest && event.target.closest('.dropdown_menu_button');
    if (!button) return;

    var current = button.closest('.dropdown_menu');
    $('.dropdown_menu').not(current).each(function() {
      var menu = $(this).data('aaDropdownMenu');
      if (menu && menu.isOpen) menu.close();
    });
  }, true);

})(jQuery);
