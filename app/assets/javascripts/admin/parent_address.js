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
  let $bookDeliveryLocationWarning = $('#parent_book_delivery_location_input .inline-hints');

  let $childSupportParent1FirstName = $('#child_support_parent1_first_name');
  let $childSupportParent1LastName = $('#child_support_parent1_last_name');
  let $childSupportCurrentChildFirstName = $('#child_support_current_child_first_name');
  let $childSupportCurrentChildLastName = $('#child_support_current_child_last_name');
  let $childSupportCurrentChildSourceChannel = $('#child_support_current_child_source_channel');
  let $childSupportCurrentChildSourceName = $('#child_support_current_child_source_name');
  let $childSupportParent1BookDeliveryLocation = $('#child_support_current_child_attributes_parent1_attributes_book_delivery_location');
  let $childSupportParent1LetterboxNameInput = $('#child_support_current_child_attributes_parent1_attributes_letterbox_name_input');
  let $childSupportParent1LetterboxNameLabel = $('label[for="child_support_current_child_attributes_parent1_attributes_letterbox_name"]');
  let $childSupportParent1BookDeliveryOrganisationNameInput = $('#child_support_current_child_attributes_parent1_attributes_book_delivery_organisation_name_input')
  let $childSupportParent1BookDeliveryOrganisationNameLabel = $('label[for="child_support_current_child_attributes_parent1_attributes_book_delivery_organisation_name_input"]');
  let $childSupportParent1BookDeliveryOrganisationName = $('#child_support_current_child_attributes_parent1_attributes_book_delivery_organisation_name');
  let $childSupportParent1AttentionToInput = $('#child_support_current_child_attributes_parent1_attributes_attention_to_input');
  let $childSupportParent1AttentionTo = $('#child_support_current_child_attributes_parent1_attributes_attention_to');
  let $childSupportParent1bookDeliveryLocationWarning = $('#child_support_current_child_attributes_parent1_attributes_book_delivery_location_input .inline-hints');

  handle_form(
    $parentFirstName,
    $parentLastName,
    $currentChildFirstName,
    $currentChildLastName,
    $currentChildSourceChannel,
    $currentChildSourceName,
    $parentBookDeliveryLocation,
    $parentLetterboxNameInput,
    $parentLetterboxNameLabel,
    $parentBookDeliveryOrganisationNameInput,
    $parentBookDeliveryOrganisationNameLabel,
    $parentBookDeliveryOrganisationName,
    $parentAttentionToInput,
    $parentAttentionTo,
    $bookDeliveryLocationWarning
  );

  handle_form(
    $childSupportParent1FirstName,
    $childSupportParent1LastName,
    $childSupportCurrentChildFirstName,
    $childSupportCurrentChildLastName,
    $childSupportCurrentChildSourceChannel,
    $childSupportCurrentChildSourceName,
    $childSupportParent1BookDeliveryLocation,
    $childSupportParent1LetterboxNameInput,
    $childSupportParent1LetterboxNameLabel,
    $childSupportParent1BookDeliveryOrganisationNameInput,
    $childSupportParent1BookDeliveryOrganisationNameLabel,
    $childSupportParent1BookDeliveryOrganisationName,
    $childSupportParent1AttentionToInput,
    $childSupportParent1AttentionTo,
    $childSupportParent1bookDeliveryLocationWarning
  );

  function handle_form(
    parentFirstName,
    parentLastName,
    currentChildFirstName,
    currentChildLastName,
    currentChildSourceChannel,
    currentChildSourceName,
    parentBookDeliveryLocation,
    parentLetterboxNameInput,
    parentLetterboxNameLabel,
    parentBookDeliveryOrganisationNameInput,
    parentBookDeliveryOrganisationNameLabel,
    parentBookDeliveryOrganisationName,
    parentAttentionToInput,
    parentAttentionTo,
    bookDeliveryLocationWarning
    ) {
    bookDeliveryLocationWarning.hide();
    setLabels(parentBookDeliveryLocation, parentLetterboxNameLabel, parentBookDeliveryOrganisationNameLabel);
    hideInputs(parentBookDeliveryLocation, parentBookDeliveryOrganisationNameInput, parentAttentionToInput, parentLetterboxNameInput);
    showInputs(parentBookDeliveryLocation, parentLetterboxNameInput, parentAttentionToInput, parentBookDeliveryOrganisationNameInput);
    updateBookDeliveryOrganisation(parentBookDeliveryLocation, currentChildSourceChannel, parentBookDeliveryOrganisationName, currentChildSourceName);

    parentBookDeliveryLocation.on('change', function() {
      if ($(this).val() === 'temporary_shelter' && currentChildSourceChannel.val() === 'pmi') {
        bookDeliveryLocationWarning.show();
      } else {
        bookDeliveryLocationWarning.hide();
      }
      updateBookDeliveryOrganisation($(this), currentChildSourceChannel, parentBookDeliveryOrganisationName, currentChildSourceName);
      switch ($(this).val()) {
        case 'relative_home':
        case 'temporary_shelter':
        case 'association':
        case 'police_or_military_station':
          parentAttentionTo.val(`${parentFirstName.val()} ${parentLastName.val()}`);
          break;
        case 'pmi':
          if (currentChildFirstName.val() !== undefined && currentChildLastName.val() !== undefined) {
            parentAttentionTo.val(`${currentChildFirstName.val()} ${currentChildLastName.val()}`);
          }
          break;
      }
      setLabels($(this), parentLetterboxNameLabel, parentBookDeliveryOrganisationNameLabel);
      hideInputs($(this), parentBookDeliveryOrganisationNameInput, parentAttentionToInput, parentLetterboxNameInput);
      showInputs($(this), parentLetterboxNameInput, parentAttentionToInput, parentBookDeliveryOrganisationNameInput);
    });
  }

  function updateBookDeliveryOrganisation(
    parentBookDeliveryLocation,
    currentChildSourceChannel,
    parentBookDeliveryOrganisationName,
    currentChildSourceName) {
    let parentBookDeliveryOrganisationNameValue = parentBookDeliveryOrganisationName.val() || currentChildSourceName.val();
    if (parentBookDeliveryLocation.val() === 'pmi' && currentChildSourceChannel.val() === 'pmi') {
      parentBookDeliveryOrganisationName
        .val(parentBookDeliveryOrganisationNameValue)
        .css({'background-color': '#A7ACB2'});
    } else {
      parentBookDeliveryOrganisationName
        .css({'background-color': ''})
        .prop('readonly', false);
    }
  }

  function setLabels(
    parentBookDeliveryLocation,
    parentLetterboxNameLabel,
    parentBookDeliveryOrganisationNameLabel) {
    switch (parentBookDeliveryLocation.val()) {
      case 'home':
        parentLetterboxNameLabel.html('Nom de famille sur la boîte aux lettres<abbr>*</abbr>');
        break;
      case 'relative_home':
        parentLetterboxNameLabel.html('Nom de la personne hébergeant la famille (nom sur la boîte aux lettres)<abbr>*</abbr>');
        break;
      case 'pmi':
        parentBookDeliveryOrganisationNameLabel.html('Nom de la PMI<abbr>*</abbr>');
        break;
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        parentBookDeliveryOrganisationNameLabel.html("Nom complet de la structure d'accueil (hotêl, résidence sociale...)<abbr>*</abbr>");
        break;
    }
  }

  function hideInputs(
    parentBookDeliveryLocation,
    parentBookDeliveryOrganisationNameInput,
    parentAttentionToInput,
    parentLetterboxNameInput) {
    switch (parentBookDeliveryLocation.val()) {
      case 'home':
        parentBookDeliveryOrganisationNameInput.hide().prop('disabled', true);
        parentAttentionToInput.hide().prop('disabled', true);
        break;
      case 'relative_home':
        parentBookDeliveryOrganisationNameInput.hide().prop('disabled', true);
        break;
      case 'pmi':
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        parentLetterboxNameInput.hide().prop('disabled', true);
        break;
    }
  }

  function showInputs(
    parentBookDeliveryLocation,
    parentLetterboxNameInput,
    parentAttentionToInput,
    parentBookDeliveryOrganisationNameInput) {
    switch (parentBookDeliveryLocation.val()) {
      case 'home':
        parentLetterboxNameInput.show().prop('disabled', false);
        break;
      case 'relative_home':
        parentLetterboxNameInput.show().prop('disabled', false);
        parentAttentionToInput.show().prop('disabled', false);
        break;
      case 'pmi':
      case 'temporary_shelter':
      case 'association':
      case 'police_or_military_station':
        parentBookDeliveryOrganisationNameInput.show().prop('disabled', false);
        parentAttentionToInput.show().prop('disabled', false);
        break;
    }
  }
});
