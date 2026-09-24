(function($) {

  // Le crayon des cartes parent/enfant quitte la fiche de suivi : on enregistre la
  // saisie en cours avant de naviguer, sinon l'auto-save en vol serait avorté.
  $(document).on('click', 'a.js-save-before-leave', function(event) {
    if (typeof window.adminNavigateAfterSave !== 'function') return; // navigation normale

    event.preventDefault();
    window.adminNavigateAfterSave(this.href);
  });

})(jQuery);
