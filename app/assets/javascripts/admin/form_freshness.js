// Détecte qu'un formulaire d'édition affiche un contenu périmé — la fiche ayant
// été modifiée ailleurs pendant que l'onglet était ouvert — et laisse
// l'utilisateur arbitrer : actualiser, ou écraser sciemment.
//
// Conséquence structurante : les enregistrements sont sérialisés. Chaque envoi
// attend la retombée du précédent (whenNoSaveInFlight) et ceux qui surviennent
// pendant un arbitrage sont avalés (arbitrationPending). Les modifications ne
// sont pas perdues pour autant — le formulaire n'est sérialisé qu'au rejeu —
// mais la latence des auto-saves s'additionne, et un envoi peut rester en
// attente alors que rien n'est encore parti sur le réseau.
(function($) {

  // Borne les lectures de fraîcheur : sans elle, un serveur qui accepte la
  // connexion sans répondre laisse la promesse pendante. Le chemin d'échec
  // existe alors mais ne se déclenche jamais, et l'envoi suspendu n'est pas
  // rejoué.
  const REQUEST_TIMEOUT_MS = 8000;

  // Délai au-delà duquel un enregistrement qui n'est jamais retombé est
  // considéré comme abandonné. L'envoi de form.js n'a pas de timeout et
  // l'onglet peut être suspendu : sans ce garde, `savesInFlight` resterait en
  // l'air et plus aucune vérification n'aboutirait.
  const SAVE_IDLE_TIMEOUT_MS = 30000;

  // Plancher entre deux vérifications déclenchées par la saisie : `input` se
  // déclenche à chaque caractère, et sans plancher on interroge le serveur au
  // rythme du réseau. L'envoi, lui, n'y est jamais soumis — c'est le dernier
  // rempart.
  const EDIT_CHECK_THROTTLE_MS = 10000;

  const STALE_MESSAGE_PREFIX = 'Cette fiche a été modifiée ailleurs. Ce que vous voyez n’est ' +
    'plus à jour.\n\n' +
    'OK pour actualiser (votre saisie en cours sera perdue), ';

  // Deux moments, deux conséquences : à la saisie rien n'est encore parti, alors
  // qu'au moment de l'envoi l'écrasement est immédiat. Un message unique
  // mentirait sur l'un des deux. Le libellé est porté par la vérification
  // elle-même (cf. ensureCheck) et non par le callback qui la consomme : une
  // même vérification sert la frappe et l'envoi, et c'est l'envoi qui doit
  // dicter ce qu'on annonce.
  const STALE_MESSAGE_ON_EDIT = STALE_MESSAGE_PREFIX +
    'Annuler pour continuer : votre enregistrement écrasera la modification faite ailleurs.';

  const STALE_MESSAGE_ON_SUBMIT = STALE_MESSAGE_PREFIX +
    'Annuler pour enregistrer quand même : la modification faite ailleurs sera écrasée.';

  // Formulé pour rester vrai avant comme après l'enregistrement qui écrase :
  // le bandeau est une trace, pas une alerte en attente.
  const NOTICE_MESSAGE = 'Vous avez choisi de poursuivre malgré une modification faite ' +
    'ailleurs : vos enregistrements l’écrasent.';


  // ---------------------------------------------------------------------------
  // Freshness — comparaison de l'état reflété par la page avec celui du serveur
  // ---------------------------------------------------------------------------

  const Freshness = (function() {
    let updatedAtUrl;
    let baseline = null;     // Number | null — null : référence perdue, à reconstruire.
    let savesInFlight = 0;
    let idleWaiters = [];

    const rejectWith = function(message) {
      const d = $.Deferred();
      d.reject(new Error(message));
      return d.promise();
    };

    // Rejette sur échec, sur dépassement de délai comme sur date illisible :
    // aucune valeur de repli ne pourrait être prise pour « à jour » sans
    // mentir. Les appelants traitent le rejet comme « vérification
    // impossible » : ils n'alertent pas, et ne bloquent pas l'enregistrement.
    const fetchUpdatedAt = function() {
      return $.ajax({
        url: updatedAtUrl,
        dataType: 'json',
        timeout: REQUEST_TIMEOUT_MS,
        cache: false
      }).then(function(response) {
        const parsed = Date.parse(response.updated_at);
        return isNaN(parsed) ? rejectWith('updated_at non parseable') : parsed;
      });
    };

    const releaseWaiters = function() {
      const waiters = idleWaiters;
      idleWaiters = [];
      waiters.forEach(function(waiter) { waiter.resolve(); });
    };

    // Un enregistrement jamais retombé est déclaré abandonné : sa requête a pu
    // atteindre la base, donc la référence devient inconnue. Les vérifications
    // reprennent aussitôt — les laisser attendre reviendrait à payer ce délai
    // sur chaque envoi, indéfiniment.
    const abandonSavesInFlight = function() {
      savesInFlight = 0;
      baseline = null;
      releaseWaiters();
    };

    // Attend que nos propres enregistrements soient retombés. Sans cela, la
    // comparaison prendrait notre sauvegarde en vol pour une modification
    // concurrente — et l'alerte porterait sur notre propre travail.
    //
    // L'attente plutôt que le rejet immédiat : rejeter ferait consommer le
    // créneau de throttle par une vérification qui n'a rien demandé au serveur,
    // et la frappe resterait muette après la sauvegarde. Ici le check aboutit
    // normalement, une fois la sauvegarde retombée.
    const whenNoSaveInFlight = function() {
      if (savesInFlight === 0) return $.Deferred().resolve().promise();

      const waiter = $.Deferred();
      const timer = setTimeout(abandonSavesInFlight, SAVE_IDLE_TIMEOUT_MS);
      waiter.always(function() { clearTimeout(timer); });
      idleWaiters.push(waiter);
      return waiter.promise();
    };

    // Retourne { stale, currentUpdatedAt }. `currentUpdatedAt` est nécessaire
    // pour mémoriser la version acceptée : sans lui, impossible de distinguer
    // « même modification concurrente, déjà acceptée » de « nouvelle
    // modification concurrente ».
    //
    // Référence perdue : la valeur lue la remplace et le tour est déclaré
    // indécidable. On ne peut pas savoir si l'écart vient de notre propre
    // enregistrement ou d'un tiers — alerter serait un faux positif, et se
    // taire en se prétendant à jour masquerait le doute. La protection reprend
    // au tour suivant.
    const checkStaleness = function() {
      return whenNoSaveInFlight().then(fetchUpdatedAt).then(function(currentUpdatedAt) {
        if (baseline === null) {
          baseline = currentUpdatedAt;
          return rejectWith('référence reconstruite');
        }

        return { stale: currentUpdatedAt > baseline, currentUpdatedAt: currentUpdatedAt };
      });
    };

    const saveStarted = function() {
      savesInFlight += 1;
    };

    // Le clamp couvre l'enregistrement déclaré abandonné dont l'`ajax:complete`
    // finit malgré tout par arriver : le compteur a déjà été remis à zéro.
    // rails-ujs, lui, n'émet jamais `complete` sans `send` — un envoi annulé
    // plus tôt passe par `ajax:stopped`.
    const releaseSave = function() {
      savesInFlight = Math.max(0, savesInFlight - 1);
      if (savesInFlight === 0) releaseWaiters();
    };

    // Notre propre enregistrement vient de faire avancer updated_at : sans
    // recalage, la fiche se croirait périmée de son propre fait. Recalage
    // impossible : la référence est déclarée perdue plutôt que laissée en
    // arrière, où elle produirait précisément cette fausse alerte à chaque
    // vérification suivante.
    //
    // Le compteur n'est relâché qu'une fois la référence réglée, pour ne pas
    // laisser de fenêtre où l'on comparerait encore à l'ancienne.
    const saveFinished = function() {
      return fetchUpdatedAt()
        .then(function(updatedAt) { baseline = updatedAt; },
              function() { baseline = null; })
        .always(releaseSave);
    };

    // La référence est celle rendue par le serveur avec le formulaire : c'est
    // exactement l'état que la page affiche. Absente ou illisible — page servie
    // par une version antérieure du gabarit —, la première vérification la
    // reconstruit. L'appelant ne doit donc pas sortir si `renderedUpdatedAt`
    // manque : c'est `url` qui conditionne la garde.
    const init = function(url, renderedUpdatedAt) {
      updatedAtUrl = url;
      baseline = Date.parse(renderedUpdatedAt);
      if (isNaN(baseline)) baseline = null;
    };

    return {
      init: init,
      checkStaleness: checkStaleness,
      saveStarted: saveStarted,
      saveFinished: saveFinished
    };
  })();


  // ---------------------------------------------------------------------------
  // OverwriteConsent — décision de l'utilisateur d'écraser la modification distante
  // ---------------------------------------------------------------------------

  // Le consentement porte sur une version précise de l'état distant. Si une
  // nouvelle modification concurrente survient après l'acceptation, elle
  // constitue un état nouveau : l'utilisateur doit être prévenu à nouveau,
  // faute de quoi son « j'écrase » couvrirait silencieusement des changements
  // qu'il n'a jamais vus.
  const OverwriteConsent = (function() {
    let acceptedStaleVersion = null;

    const isAcceptedFor = function(currentUpdatedAt) {
      return acceptedStaleVersion !== null && currentUpdatedAt <= acceptedStaleVersion;
    };

    const accept = function(currentUpdatedAt) {
      acceptedStaleVersion = currentUpdatedAt;
    };

    const reset = function() {
      acceptedStaleVersion = null;
    };

    return {
      isAcceptedFor: isAcceptedFor,
      accept: accept,
      reset: reset
    };
  })();


  // ---------------------------------------------------------------------------
  // StaleNotice — trace visible d'un écrasement consenti
  // ---------------------------------------------------------------------------

  // « Annuler » est une décision destructrice prise dans une boîte qui
  // disparaît aussitôt. Sans trace, l'utilisateur ne peut plus revenir dessus —
  // faute de savoir qu'il y a quelque chose à reconsidérer : plus rien à
  // l'écran ne dit que ses enregistrements écrasent le travail d'un autre. Le
  // bandeau reste jusqu'au rechargement, seule issue à la situation.
  const StaleNotice = (function() {
    let form;
    let shown = false;

    const build = function() {
      const $refresh = $('<button>', {
        // `type` explicite : dans un formulaire, un bouton sans type soumet.
        type: 'button',
        class: 'form-freshness-notice-refresh',
        text: 'Actualiser la page'
      }).on('click', function() {
        // Pas d'`adminDiscardFormChanges` ici, contrairement au « OK » de la
        // boîte : ce clic-là n'a été précédé d'aucune confirmation. On laisse
        // le garde beforeunload de form.js prévenir s'il reste de la saisie
        // qu'aucune requête n'emporte.
        window.location.reload();
      });

      return $('<div>', { class: 'form-freshness-notice' })
        .append($('<span>', { text: NOTICE_MESSAGE }))
        .append($refresh);
    };

    // Idempotent : un second consentement, portant sur une modification
    // concurrente plus récente, ne doit pas empiler un deuxième bandeau.
    const show = function() {
      if (shown || !form) return;

      shown = true;
      $(form).prepend(build());
    };

    const init = function(theForm) {
      form = theForm;
    };

    return { init: init, show: show };
  })();


  // ---------------------------------------------------------------------------
  // StaleGuard — politique d'alerte et de blocage de l'envoi
  // ---------------------------------------------------------------------------

  const StaleGuard = (function() {
    let pendingCheck = null;      // Promise<verdict>, partagée frappe / envoi
    let pendingMessage = null;    // Libellé de la boîte, pour cette vérification
    let lastCheckStartedAt = 0;
    let pageReloading = false;

    // `window.confirm` est synchrone et bloque la boucle d'évènements : toute
    // la politique repose sur ce comportement. Le garde `pageReloading` évite
    // d'empiler une seconde boîte par-dessus la page qui s'en va.
    const confirmReload = function(message) {
      if (pageReloading) return true;
      if (!window.confirm(message)) return false;

      pageReloading = true;
      // La saisie en cours est volontairement abandonnée : sans ce
      // renoncement, le garde beforeunload de form.js poserait une seconde
      // confirmation, native celle-là.
      if (typeof window.adminDiscardFormChanges === 'function') {
        window.adminDiscardFormChanges();
      }
      window.location.reload();
      return true;
    };

    // Point unique où une boîte se pose et où le consentement est enregistré.
    // Retourne true si un rechargement est engagé — l'appelant doit alors
    // s'arrêter net. Sinon false, il peut continuer.
    //
    // Le repli sur le message d'édition couvre le cas anormal où `handleStale`
    // serait appelé sans qu'`ensureCheck` ait posé le libellé : une boîte ne
    // doit jamais s'afficher vide.
    const handleStale = function(result) {
      if (!result.stale) return false;
      if (OverwriteConsent.isAcceptedFor(result.currentUpdatedAt)) return false;
      if (confirmReload(pendingMessage || STALE_MESSAGE_ON_EDIT)) return true;

      OverwriteConsent.accept(result.currentUpdatedAt);
      StaleNotice.show();
      return false;
    };

    // Une seule vérification court à la fois, partagée entre la frappe et
    // l'envoi. L'envoi s'y accroche pour ne pas partir avant que la fraîcheur
    // soit établie — c'est ce qui empêche l'auto-save d'écraser en silence. Il
    // en reprend au passage le libellé à son compte : c'est lui que
    // l'utilisateur doit arbitrer.
    const ensureCheck = function(message) {
      if (message === STALE_MESSAGE_ON_SUBMIT) pendingMessage = message;
      if (pendingCheck) return pendingCheck;

      pendingMessage = message;
      lastCheckStartedAt = Date.now();
      pendingCheck = Freshness.checkStaleness();
      // Attaché avant tout `.then` appelant : le champ est vidé avant que les
      // handlers ne s'exécutent, si bien qu'un handler peut relancer une
      // vérification sans récupérer la promesse déjà résolue.
      pendingCheck.always(function() { pendingCheck = null; });
      return pendingCheck;
    };

    // La fiche a pu être modifiée ailleurs pendant que l'onglet était ouvert :
    // on prévient dès la saisie, avant qu'elle ne soit perdue. Une vérification
    // en vol couvre la frappe en cours ; le plancher borne les suivantes. Rien
    // n'est mis en cache : un verdict déjà rendu a déjà posé sa boîte ou
    // enregistré son consentement, le rejouer serait sans effet.
    const onEdit = function(form) {
      $(form).on('input change', function() {
        if (pendingCheck) return;
        if (Date.now() - lastCheckStartedAt < EDIT_CHECK_THROTTLE_MS) return;

        ensureCheck(STALE_MESSAGE_ON_EDIT).then(handleStale, function() {
          // Vérification impossible : on n'alerte pas à tort.
        });
      });
    };

    // Dernier rempart, pour la fiche devenue périmée après le début de la
    // saisie : la vérification étant asynchrone, on suspend l'envoi le temps
    // d'interroger la base, puis on le relance — parce que la fiche est à jour,
    // ou parce que l'utilisateur a choisi d'écraser la modification
    // concurrente, ici ou plus tôt à la saisie.
    //
    // Sur un formulaire remote, annuler l'évènement `submit` ne sert à rien :
    // rails-ujs branche handleRemote en délégation sur `document` et ignore
    // defaultPrevented, si bien que la requête partait quand même — et la
    // relance en déclenchait une seconde. Le hook `ajax:before`, lui, est bien
    // annulable.
    const onSubmit = function(form) {
      const remote = form.getAttribute('data-remote') === 'true';
      let replayingSubmit = false;
      let arbitrationPending = false;

      $(form).on(remote ? 'ajax:before' : 'submit', function(event) {
        // Les évènements rails-ujs remontent : on ignore ceux d'un élément
        // remote imbriqué, qui n'est pas l'enregistrement de la fiche.
        if (event.target !== form) return;

        if (replayingSubmit) {
          replayingSubmit = false;
          return;
        }

        // Un envoi est déjà suspendu derrière le verdict en cours. `replayingSubmit`
        // ne rattrape que le rejeu d'un envoi donné : deux `ajax:before` distincts
        // s'abonneraient au même verdict et se rejoueraient chacun, soit deux
        // requêtes pour un seul arbitrage. Ignorer le second ne perd rien — le
        // formulaire n'est sérialisé qu'au rejeu, donc les modifications faites
        // entre-temps partent avec l'envoi survivant.
        if (arbitrationPending) {
          event.preventDefault();
          return;
        }

        const submitter = event.originalEvent && event.originalEvent.submitter;
        event.preventDefault();

        const submit = function() {
          arbitrationPending = false;
          // L'envoi est déclenché de façon synchrone : au retour, le drapeau a
          // été consommé — sauf si la validation HTML5 a bloqué l'envoi, auquel
          // cas on le désarme pour ne pas sauter la vérification suivante.
          replayingSubmit = true;
          if (remote) {
            Rails.fire(form, 'submit');
          } else if (form.requestSubmit) {
            form.requestSubmit(submitter);
          } else {
            form.submit();
          }
          replayingSubmit = false;
        };

        arbitrationPending = true;
        ensureCheck(STALE_MESSAGE_ON_SUBMIT).then(function(result) {
          // Rechargement engagé : le drapeau reste levé, la page s'en va.
          if (handleStale(result)) return;
          submit();
        }, submit); // vérification impossible : on ne bloque pas l'enregistrement
      });
    };

    return {
      onEdit: onEdit,
      onSubmit: onSubmit
    };
  })();


  // ---------------------------------------------------------------------------
  // SaveWatcher — branchement des évènements rails-ujs sur nos propres envois
  // ---------------------------------------------------------------------------

  // Un formulaire remote ne recharge pas la page : c'est à nous de recaler la
  // référence après chaque enregistrement. Ailleurs, le rechargement rejoue
  // init() et s'en charge.
  const SaveWatcher = (function() {
    const watch = function(form) {
      $(form).on('ajax:send', function(event) {
        if (event.target !== form) return;
        Freshness.saveStarted();
      });

      $(form).on('ajax:complete', function(event) {
        if (event.target !== form) return;
        // Le « j'écrase » ne valait que pour la version acceptée : une
        // modification concurrente postérieure doit à nouveau donner lieu à une
        // alerte.
        OverwriteConsent.reset();
        Freshness.saveFinished();
      });
    };

    return { watch: watch };
  })();


  // ---------------------------------------------------------------------------
  // init — orchestrateur
  // ---------------------------------------------------------------------------

  // Le marqueur est unique par page : `.first()` documente la contrainte plutôt
  // qu'il ne la fait respecter. Un second marqueur serait ignoré en silence.
  //
  // Les handlers sont branchés de façon synchrone : tout amorçage asynchrone
  // rouvrirait une fenêtre où l'auto-save de form.js, lui déjà armé, partirait
  // sans vérification — et sans passer par SaveWatcher, donc en laissant la
  // référence en arrière.
  const init = function() {
    const $marker = $('.js-form-freshness').first();
    if ($marker.length === 0) return;

    const form = $marker.closest('form')[0];
    if (!form) return;

    const url = $marker.data('url');
    if (!url) return;

    Freshness.init(url, $marker.data('updatedAt'));
    StaleNotice.init(form);
    StaleGuard.onEdit(form);
    StaleGuard.onSubmit(form);
    SaveWatcher.watch(form);
  };

  $(document).ready(init);

})(jQuery);
