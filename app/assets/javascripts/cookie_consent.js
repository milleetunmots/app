window.addEventListener('load', function () {
  if (typeof CookieConsent === 'undefined') {
    console.error("CookieConsent non chargé !");
    return;
  }

  CookieConsent.run({
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
          readOnly: true
      },
      analytics: {}
    },
    language: {
      default: "fr",
      translations: {
        fr: {
          consentModal: {
              title: "Bonjour, c'est l'heure des cookies 🍪",
              description: "Certains cookies sont nécessaires pour une bonne expérience sur notre site 1001mots. D’autres servent à des fins d’analyse.",
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
                      description: "Ces cookies sont utilisés pour mesurer l’audience via Google Tag Manager.",
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
    onConsent: ({ cookie }) => {
      if (cookie.categories.includes('analytics')) {
        loadGTM();
      }
    }
  });

  function loadGTM() {
    const gtmId = 'GTM-N8C43NF';
    const gtmScript = document.createElement('script');
    gtmScript.async = true;
    gtmScript.src = `https://www.googletagmanager.com/gtm.js?id=${gtmId}`;
    document.head.appendChild(gtmScript);

    const iframe = document.createElement('iframe');
    iframe.src = `https://www.googletagmanager.com/ns.html?id=${gtmId}`;
    iframe.height = 0;
    iframe.width = 0;
    iframe.style = 'display:none;visibility:hidden';
    const noscript = document.createElement('noscript');
    noscript.appendChild(iframe);
    document.body.appendChild(noscript);
  }
});
