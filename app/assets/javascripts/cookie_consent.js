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
        layout: "bar",
        position: "bottom",
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
            title: "Ce site web utilise des cookies 🍪",
            description: "1001mots utilise des cookies pour assurer le bon fonctionnement et la sécurité du site, et – avec votre accord – mesurer l’audience et analyser le trafic. Vous pouvez accepter, refuser ou paramétrer vos préférences, à l’exception des cookies strictement nécessaires.",
            acceptAllBtn: "Tout accepter",
            acceptNecessaryBtn: "Tout rejeter",
            showPreferencesBtn: "Personnaliser",
            footer: "<a href=\"https://1001mots.org/politique-de-confidentialite\" target=\"_blank\">Politique de confidentialité</a>\n<a href=\"https://1001mots.org/mentions-legales/\" target=\"_blank\">Mentions légales</a>"
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
                description: "1001mots utilise des cookies pour assurer le bon fonctionnement et la sécurité du site, et – avec votre accord – mesurer l’audience et analyser le trafic. Vous pouvez accepter, refuser ou paramétrer vos préférences, à l’exception des cookies strictement nécessaires."
              },
              {
                title: "Cookies strictement nécessaires <span class=\"pm__badge\">Obligatoire</span>",
                description: "Ces cookies sont nécessaires au bon fonctionnement de notre site Internet. Conformément à la réglementation leur dépôt ne requiert pas votre consentement. Ils nous permettent notamment d’organiser l’inscription en ligne au programme.",
                linkedCategory: "necessary",
                cookieTable: {
                  headers: {
                    name: "Nom",
                    expiration: 'Durée maximale de conservation',
                    description: "Description"
                  },
                  body: [
                    {
                      name: 'MOTS_SESSION',
                      description: 'Ce cookie est nécessaire pour pouvoir naviguer sur le site internet',
                      expiration: 'Session navigateur',
                    },
                    {
                      name: 'TIME_ZONE',
                      description: 'Ce cookie est utilisé pour connaître le fuseau horaire local de l’utilisateur afin d’afficher correctement les notions de dates et d’heure',
                      expiration: 'Session navigateur',
                    },
                    {
                      name: 'CC_COOKIE',
                      description: 'Sauvegarde de vos préférences de cookies',
                      expiration: '6 mois',
                    }
                  ]
                }
              },
              {
                title: "Cookies mesure d’audience",
                description: "Ces cookies nous permettent de générer des statistiques de fréquentation : ils nous aident à savoir quelles pages sont plus ou moins consultées et à améliorer notre site pour répondre à vos attentes. Vous pouvez vous y opposer et les supprimer en utilisant les paramètres de votre navigateur ou notre module de paramétrage de vos préférences.",
                linkedCategory: "analytics",
                cookieTable: {
                  headers: {
                    name: "Nom",
                    expiration: 'Durée maximale de conservation',
                    description: "Description"
                  },
                  body: [
                    {
                      name: '_GA',
                      description: 'Ce cookie est utilisé pour comprendre le parcours des utilisateurs sur notre site internet d’inscription. Les informations récoltées sont anonymes',
                      expiration: '1 an, 1 mois et 4 jours',
                    },
                    {
                      name: '_GA_*',
                      description: 'Ce cookie est utilisé pour comptabiliser les visites sur notre site internet d’inscription',
                      expiration: '1 an, 1 mois et 4 jours',
                    }
                  ]
                }
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
    const possibleCookieDomains = [
      window.location.hostname,
      '.' + window.location.hostname.replace(/^[^.]+\./, ''), // retirer le sous domaine si présent
      '.' + window.location.hostname
    ];

    for (let cookie of cookies) {
      const cookieName = cookie.split('=')[0].trim();
      if (cookieName.startsWith('_ga') ||
        cookieName.startsWith('_gid') ||
        cookieName.startsWith('_gat') ||
        cookieName.startsWith('_gac_') ||
        cookieName === '_gac') {
          document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
          possibleCookieDomains.forEach(domain => {
            document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=${domain};`;
            document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
          })
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
