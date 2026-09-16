(function($) {

  // Ouvre le lien dans un onglet créé par script : window.close() n'est autorisé
  // que sur les onglets ouverts par script (un target="_blank" seul ne suffit pas).
  var openInScriptedTab = function() {
    $(document).on('click', 'a.js-scripted-tab-link', function(event) {
      event.preventDefault();
      window.open(this.href, '_blank');
    });
  };

  var refreshOpener = function(opener) {
    if (typeof opener.adminReloadAfterSave === 'function') {
      opener.adminReloadAfterSave();
    } else {
      opener.location.reload();
    }
    opener.focus();
  };

  // Après sauvegarde, la fiche parent/enfant redirige vers la fiche de suivi avec
  // close_tab=1 : on rafraîchit l'onglet d'origine puis on referme celui-ci. Si le
  // navigateur refuse la fermeture, la fiche de suivi en édition est déjà affichée.
  var closeTabIfRequested = function() {
    if (new URLSearchParams(window.location.search).get('close_tab') !== '1') return;

    var opener = window.opener;
    if (opener && !opener.closed) {
      try {
        refreshOpener(opener);
      } catch (error) {
        // onglet d'origine inaccessible : on se contente de fermer celui-ci
      }
    }
    window.close();
  };

  $(document).ready(function() {
    openInScriptedTab();
    closeTabIfRequested();
  });

})(jQuery);
