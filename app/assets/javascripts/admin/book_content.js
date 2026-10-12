// Pages du livre : les cards de la galerie ouvrent une vue agrandie
// dans laquelle on feuillette avec ‹ › ou ← →, et qu'on ferme avec ×, Échap ou un clic sur le fond.
$(document).ready(function() {
  let $gallery = $('.book-gallery');
  if ($gallery.length === 0) return;

  let $cards = $gallery.find('.book-gallery-card');
  let $lightbox = $('.book-lightbox');
  let $image = $lightbox.find('.book-lightbox-image');
  let $counter = $lightbox.find('.book-lightbox-counter');
  let $closeButton = $lightbox.find('.book-lightbox-close');
  let $prevButton = $lightbox.find('.book-lightbox-prev');
  let $nextButton = $lightbox.find('.book-lightbox-next');
  let currentIndex = null;

  function show(index) {
    let $thumbnail = $cards.eq(index).find('img');
    currentIndex = index;
    $image.attr('src', $thumbnail.attr('src'));
    $image.attr('alt', $thumbnail.attr('alt'));
    $counter.text((index + 1) + ' / ' + $cards.length);
    $prevButton.prop('disabled', index === 0);
    $nextButton.prop('disabled', index === $cards.length - 1);

    // Un bouton désactivé perd le focus : on le reporte sur un bouton encore utilisable.
    if ($(document.activeElement).is(':disabled')) focusableButtons().first().trigger('focus');
  }

  function focusableButtons() {
    return $lightbox.find('button:enabled');
  }

  // Garde le focus clavier dans la vue agrandie tant qu'elle est ouverte.
  function trapFocus(event) {
    let $buttons = focusableButtons();
    let first = $buttons.get(0);
    let last = $buttons.get($buttons.length - 1);

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    } else if (!$.contains($lightbox[0], document.activeElement)) {
      event.preventDefault();
      first.focus();
    }
  }

  function open(index) {
    show(index);
    $lightbox.prop('hidden', false);
    $('body').addClass('book-lightbox-open');
    $closeButton.trigger('focus');
  }

  function close() {
    $lightbox.prop('hidden', true);
    $('body').removeClass('book-lightbox-open');
    $cards.eq(currentIndex).trigger('focus');
    currentIndex = null;
  }

  function previous() {
    if (currentIndex > 0) show(currentIndex - 1);
  }

  function next() {
    if (currentIndex < $cards.length - 1) show(currentIndex + 1);
  }

  $cards.on('click', function(event) {
    event.preventDefault();
    open($cards.index(this));
  });

  $closeButton.on('click', close);
  $prevButton.on('click', previous);
  $nextButton.on('click', next);

  // Seul un clic sur le fond ferme : pas sur l'image ni sur les boutons.
  $lightbox.on('click', function(event) {
    if (event.target === this) close();
  });

  $(document).on('keydown', function(event) {
    if (currentIndex === null) return;

    if (event.key === 'Escape') close();
    else if (event.key === 'ArrowLeft') previous();
    else if (event.key === 'ArrowRight') next();
    else if (event.key === 'Tab') trapFocus(event);
  });
});
