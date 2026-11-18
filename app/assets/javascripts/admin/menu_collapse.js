// Menu latéral masquable (cf. admin/menu_collapse.sass). Le choix est retenu dans ce
// navigateur. La classe est posée sur <html> dès l'exécution de ce script, chargé dans le
// <head>, pour que la page s'affiche directement avec le menu masqué.
(function() {
  var STORAGE_KEY = 'admin-menu-collapsed';
  var COLLAPSED_CLASS = 'menu-collapsed';
  var root = document.documentElement;

  var storedCollapsed = function() {
    try {
      return window.localStorage.getItem(STORAGE_KEY) === '1';
    } catch (e) {
      return false;
    }
  };

  var storeCollapsed = function(collapsed) {
    try {
      if (collapsed) {
        window.localStorage.setItem(STORAGE_KEY, '1');
      } else {
        window.localStorage.removeItem(STORAGE_KEY);
      }
    } catch (e) {
      // Stockage indisponible (navigation privée) : le choix vaut pour cette page seulement
    }
  };

  var renderButton = function(button) {
    var collapsed = root.classList.contains(COLLAPSED_CLASS);
    var label = collapsed ? 'Garder le menu ouvert' : 'Masquer le menu';
    button.setAttribute('aria-label', label);
    button.setAttribute('title', label);
    button.setAttribute('aria-pressed', collapsed ? 'true' : 'false');
  };

  if (storedCollapsed()) root.classList.add(COLLAPSED_CLASS);

  document.addEventListener('DOMContentLoaded', function() {
    var siteTitle = document.getElementById('site_title');
    if (!siteTitle || !document.getElementById('tabs')) return;

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'menu-collapse-toggle';
    siteTitle.appendChild(button);
    renderButton(button);

    button.addEventListener('click', function() {
      var collapsed = root.classList.toggle(COLLAPSED_CLASS);
      storeCollapsed(collapsed);
      renderButton(button);
    });
  });
})();
