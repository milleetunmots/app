window.addEventListener('load', function () {
  if (typeof CookieConsent === 'undefined') {
    console.error("CookieConsent non chargé !");
    return;
  }

  const cc = CookieConsent;
  let gtmLoaded = false;

  cc.run({
    guiOptions: {
      consentModal: {
        layout: "box",
        position: "bottom left",
        equalWeightButtons: true,
        flipButtons: false
      },
      preferencesModal: {
        layout: "box",
        position: "right",
        equalWeightButtons: true,
        flipButtons: false
      }
    },
    categories: {
      necessary: {
        enabled: true,
        readOnly: true
      },
      analytics: {
        enabled: false,
        readOnly: false
      }
    },
    language: {
      default: "fr",
      translations: {
        fr: {
          consentModal: {
            title: "Bonjour, c'est l'heure des cookies 🍪",
            description: "Certains cookies sont nécessaires pour une bonne expérience sur notre site 1001mots. D'autres servent à des fins d'analyse.",
            acceptAllBtn: "Tout accepter",
            acceptNecessaryBtn: "Tout rejeter",
            showPreferencesBtn: "Gérer les préférences",
            footer: "<a href=\"#link\">Politique de confidentialité</a>\n<a href=\"#link\">Termes et conditions</a>"
          },
          preferencesModal: {
            title: "Préférences de cookies",
            acceptAllBtn: "Tout accepter",
            acceptNecessaryBtn: "Tout rejeter",
            savePreferencesBtn: "Sauvegarder les préférences",
            closeIconLabel: "Fermer la modale",
            serviceCounterLabel: "Services",
            sections: [
              {
                title: "Utilisation des Cookies",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
              },
              {
                title: "Cookies Strictement Nécessaires <span class=\"pm__badge\">Toujours Activé</span>",
                description: "Ces cookies sont essentiels au bonfonctionnement du site.",
                linkedCategory: "necessary"
              },
              {
                title: "Cookies Analytiques",
                description: "Ces cookies sont utilisés pour mesurer l'audience via Google Tag Manager.",
                linkedCategory: "analytics"
              },
              {
                title: "Plus d'informations",
                description: "Contactez-nous pour toutes questions concernant les cookies."
              }
            ]
          }
        }
      },
      autoDetect: "browser"
    },
    onFirstConsent: function({ cookie }) {
      if (cookie.categories.includes('analytics')) {
        loadGTM();
      }
    },
    onChange: function({ cookie, changedCategories }) {
      if (changedCategories.includes('analytics')) {
        if (cookie.categories.includes('analytics')) {
          if (!gtmLoaded) loadGTM();
        } else {
          removeGTMCookies();
          removeGTMTags();
          console.log("Consentement analytics retiré");
        }
      }
    }
  });

  document.getElementById('cookie-settings')?.addEventListener('click', function() {
    cc.showPreferences();
  });


  function loadGTM() {
    if (gtmLoaded) return;

    const gtmId = 'GTM-N8C43NF';

    (function(w,d,s,l,i){
      w[l]=w[l]||[];
      w[l].push({'gtm.start': new Date().getTime(),event:'gtm.js'});
      var f=d.getElementsByTagName(s)[0],
      j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';
      j.async=true;
      j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl;
      f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer',gtmId);

    const iframe = document.createElement('iframe');
    iframe.src = `https://www.googletagmanager.com/ns.html?id=${gtmId}`;
    iframe.height = 0;
    iframe.width = 0;
    iframe.style = 'display:none;visibility:hidden';
    const noscript = document.createElement('noscript');
    noscript.appendChild(iframe);
    document.body.appendChild(noscript);

    gtmLoaded = true;
  }

  function removeGTMCookies() {
    const cookies = document.cookie.split(';');

    for (let cookie of cookies) {
      const cookieName = cookie.split('=')[0].trim();
      if (cookieName.startsWith('_ga') ||
        cookieName.startsWith('_gid') ||
        cookieName.startsWith('_gat') ||
        cookieName.startsWith('_gac_') ||
        cookieName === '_gac') {

        document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
        document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.${window.location.hostname};`;
      }
    }
  }

  function removeGTMTags() {
    const gtmScripts = document.querySelectorAll(`script[src*="googletagmanager.com"]`);
    gtmScripts.forEach(script => script.remove());

    const gtmIframes = document.querySelectorAll(`iframe[src*="googletagmanager.com"]`);
    gtmIframes.forEach(iframe => iframe.remove());

    window.dataLayer = [];
    gtmLoaded = false;
    window.google_tag_manager = undefined;
  }

});
