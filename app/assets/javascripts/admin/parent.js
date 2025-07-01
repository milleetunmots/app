$(document).ready(function() {
  let $parentFirstName = $('#parent_first_name');
  let $parentLastName = $('#parent_last_name');
  let $currentChildFirstName = $('#parent_current_child_first_name');
  let $currentChildLastName = $('#parent_current_child_last_name');
  let $currentChildSourceChannel = $('#parent_current_child_source_channel');
  let $currentChildSourceName = $('#parent_current_child_source_name');
  let $parentBookDeliveryLocation = $('#parent_book_delivery_location');
  let $parentLetterboxNameInput = $('#parent_letterbox_name_input');
  let $parentLetterboxNameLabel = $('label[for="parent_letterbox_name"]');
  let $parentBookDeliveryOrganisationNameInput = $('#parent_book_delivery_organisation_name_input')
  let $parentBookDeliveryOrganisationNameLabel = $('label[for="parent_book_delivery_organisation_name"]');
  let $parentBookDeliveryOrganisationName = $('#parent_book_delivery_organisation_name');
  let $parentAttentionToInput = $('#parent_attention_to_input');
  let $parentAttentionTo = $('#parent_attention_to');
  let $bookDeliveryLocationWarning = $('#book_delivery_location_warning');

  $parentAttentionTo.css({'background-color': '#5E6469', 'color': '#CACACA'});
  setLabels($parentBookDeliveryLocation.val());
  hideInputs($parentBookDeliveryLocation.val());
  showInputs($parentBookDeliveryLocation.val());

  $parentBookDeliveryLocation.on('change', function() {
    if ($parentBookDeliveryLocation.val() === 'temporary_shelter') {
      $bookDeliveryLocationWarning.show();
    } else {
      $bookDeliveryLocationWarning.hide();
    }

    if ($parentBookDeliveryLocation.val() === 'pmi' && $currentChildSourceChannel.val() === 'pmi') {
      $parentBookDeliveryOrganisationName.val($currentChildSourceName.val());
    } else {
      $parentBookDeliveryOrganisationName.val('');
    }

    switch ($parentBookDeliveryLocation.val()) {
      case 'relative_home':
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        $parentAttentionTo.val(`${$parentFirstName.val()} ${$parentLastName.val()}`);
        break;
      case 'pmi':
        $parentAttentionTo.val(`${$currentChildFirstName.val()} ${$currentChildLastName.val()}`);
        break;
    }
    setLabels($parentBookDeliveryLocation.val());
    hideInputs($parentBookDeliveryLocation.val());
    showInputs($parentBookDeliveryLocation.val());
  })

  function setLabels(parentBookDeliveryLocationValue) {
    switch (parentBookDeliveryLocationValue) {
      case 'home':
        $parentLetterboxNameLabel.html('Nom de famille sur la boîte aux lettres<abbr>*</abbr>');
        break;
      case 'relative_home':
        $parentLetterboxNameLabel.html('Nom de la personne hébergeant la famille (nom sur la boîte aux lettres)<abbr>*</abbr>');
        break;
      case 'pmi':
        $parentBookDeliveryOrganisationNameLabel.html('Nom de la PMI<abbr>*</abbr>');
        break;
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        $parentBookDeliveryOrganisationNameLabel.html("Nom complet de la structure d'accueil (hotêl, résidence sociale...)<abbr>*</abbr>");
        break;
    }
  }

  function hideInputs(parentBookDeliveryLocationValue) {
    switch (parentBookDeliveryLocationValue) {
      case 'home':
        $parentBookDeliveryOrganisationNameInput.hide();
        $parentAttentionToInput.hide();
        break;
      case 'relative_home':
        $parentBookDeliveryOrganisationNameInput.hide();
        break;
      case 'pmi':
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        $parentLetterboxNameInput.hide();
        break;
    }
  }

  function showInputs(parentBookDeliveryLocationValue) {
    switch (parentBookDeliveryLocationValue) {
      case 'home':
        $parentLetterboxNameInput.show();
        break;
      case 'relative_home':
        $parentLetterboxNameInput.show();
        $parentAttentionToInput.show();
        break;
      case 'pmi':
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        $parentBookDeliveryOrganisationNameInput.show();
        $parentAttentionToInput.show();
        break;
    }
  }
});
