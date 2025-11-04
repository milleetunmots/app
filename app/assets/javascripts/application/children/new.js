(function($) {
  var url = new URL(window.location.href);
  var pathName = url.pathname;
  var childrenSourceSelect = $('#child_children_source_attributes_source_id');
  var sourceDetailsInput = $('#child_children_source_attributes_details');
  var sourceDetailsAlert = $('#children_source_detail_alert');
  var bookDeliveryLocationSelect = $('#child_parent1_attributes_book_delivery_location');
  var comments = $('#child_child_support_attributes_important_information');
  var consentInputWrapper = $('.child_child_support_has_important_information_parental_consent');
  var consentCheckbox = $('#child_child_support_attributes_has_important_information_parental_consent');
  var $addressPostalCodeInput = $('#address-postal_code');
  var $postalCodeWarning = $('.child_parent1_postal_code small');
  var $submitButton = $("#inscription input[type='submit']");

  sourceDetailsInput.on('input', function() {
    const value = $(this).val().toLowerCase();
    if(value.includes('debré') || value.includes('debre')) {
      sourceDetailsAlert.show();
    } else {
      sourceDetailsAlert.hide();
    }
  });

  var changeChildrenSourceSelectOptions = function(options) {
    childrenSourceSelect.empty();
    childrenSourceSelect.select2({ data: options });
    childrenSourceSelect.data().select2.$container.addClass("form-control");
  }

  var checkIfLocalPartnerHasDepartment = function() {
    if (pathName === '/inscription5' || pathName === '/inscriptionpartenaires') {
      const selectedValue = $('select[id="child_children_source_attributes_source_id"]').val();
      if (selectedValue !== '') {
        $.ajax({
          type: 'GET',
          url: '/sources/local_partner_has_department?id='+selectedValue
        }).done(function(data) {
          $('#child_children_source_registration_department').val('');
          $('#child_children_source_registration_department').trigger('change')
          if (data.result === false) {
            $('#registration_department_select').show();
          } else {
            $('#registration_department_select').hide();
          }
        });
      }
    }
  }

  var showCafSelection = function() {
    var value = $(this).val();

    if (pathName === '/inscriptioncaf') {
      if (value === 'caf') {
        $('#child_children_source_source_id_div').show();
        // commented out to avoid selected option resetting if there's an error in form
        //changeChildrenSourceSelectOptions(window.cafOptions);
        if (window.utmCaf !== undefined) {
          childrenSourceSelect.val(window.utmCaf)
          childrenSourceSelect.trigger('change')
        }
      } else if (value === 'bao' ) {
        changeChildrenSourceSelectOptions(window.friendOption);
        childrenSourceSelect.val(window.friendOption[0].id).trigger('change');
        $('#child_children_source_source_id_div').hide();
      }
    } else if (pathName === '/inscription5' || pathName === '/inscriptionpartenaires') {
      $('#registration_department_select').hide();
      checkIfLocalPartnerHasDepartment();
    } else if (pathName === '/inscriptionmsa') {
      if (value === 'msa') {
        if (window.utmMsa !== undefined) {
          childrenSourceSelect.val(window.utmMsa)
          childrenSourceSelect.trigger('change')
        }
      }
    }
  };

  var initAddChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $fields.detach();

    $btn.click(function(e) {
      e.preventDefault();
      $container.append($fields);
      $container.removeClass('hidden');
      // only show latest rm btn
      $('.child-fields-container .btn.rm-child-btn').hide();
      $container.find('.btn.rm-child-btn').show();
      return false;
    })
  }

  var initRmChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $btn.click(function(e) {
      e.preventDefault();
      $container.addClass('hidden');
      $fields.detach();
      // re-show previous rm btn, if any
      $('.child-fields-container .btn.rm-child-btn').last().show();
      return false;
    })
  };

  var createRequirementAbbr = function(label, input) {
    if (label.find('abbr').length !== 0 ) {
      return;
    }

    label.removeClass('optional').addClass('required');
    input.removeClass('optional').addClass('required');
    input.attr('required', true);
    input.val('');
    var abbrElement = document.createElement('abbr');
    abbrElement.setAttribute('title', 'required');
    abbrElement.innerHTML = ' *'
    label.append(abbrElement);
  }

  var removeRequirementAbbr = function(label, input) {
    label.removeClass('required').addClass('optional');
    input.removeClass('required').addClass('optional');
    input.removeAttr('required');
    var abbr = label.find('abbr');
    input.val('');
    if (abbr.length === 0) {
      return;
    }

    abbr.remove();
  }

  if (comments.length && consentInputWrapper.length && consentCheckbox.length) {
    function toggleParentalConsent() {
      var commentsVal = comments.val();
      if (commentsVal.length > 0) {
        consentInputWrapper.show();
        consentCheckbox.prop('required', true);
      } else {
        consentInputWrapper.hide();
        consentCheckbox.prop('required', false);
        consentCheckbox.prop('checked', false);
      }
    }

    comments.on('input', toggleParentalConsent);
    toggleParentalConsent();
  }

  var init = function() {
    $postalCodeWarning.hide();
    $addressPostalCodeInput.on('input', function() {
      $postalCodeWarning.hide();
      if(parseInt($(this).val()) == $(this).val() && $(this).val().length == 5) {
        $postalCodeWarning.hide();
        $submitButton.prop('disabled', false);
      } else {
        $postalCodeWarning.show();
        $submitButton.prop('disabled', true);
      }
    });

    if (bookDeliveryLocationSelect.length > 0) {
      bookDeliveryLocationSelect.select2();
      bookDeliveryLocationSelect.data().select2.$container.addClass("form-control");
      addressFormDiv = $('#address_form_div');
      var bookDeliveryOrganisationNameDiv = $('#book_delivery_organisation_name_div');
      var bookDeliveryOrganisationNameLabel = $('label[for="child_parent1_attributes_book_delivery_organisation_name"]');
      var bookDeliveryOrganisationNameInput = $('#child_parent1_attributes_book_delivery_organisation_name');
      var attentionToDiv = $('#attention_to_div');
      var attentionToInput = $('#child_parent1_attributes_attention_to');
      var letterboxLabel = $('label[for="child_parent1_attributes_letterbox_name"]');
      var letterboxLabelText = 'Nom de famille sur la boîte aux lettres ';

      bookDeliveryOrganisationNameDiv.hide();
      attentionToDiv.hide();

      bookDeliveryLocationSelect.on('change', function () {
        var selectedValue = $(this).val();
        var parent1FirstName = $('#child_parent1_attributes_first_name').val();
        var parent1LastName = $('#child_parent1_attributes_last_name').val();
        var childFirstName = $('#child_first_name').val();
        var childLastName = $('#child_last_name').val();
        var letterboxDiv = $('.child_parent1_letterbox_name').first()

        var showLetterboxDiv = function(text) {
          letterboxLabel.text(text);
          createRequirementAbbr(letterboxLabel, $('#child_parent1_attributes_letterbox_name'));
          letterboxDiv.prependTo('#address_form_div');
          letterboxDiv.show();
        }
        var hideLetterboxDiv = function() {
          letterboxLabel.text(letterboxLabelText);
          removeRequirementAbbr(letterboxLabel, $('#child_parent1_attributes_letterbox_name'));
          letterboxDiv.hide();
        }
        var showBookDeliveryLocationWarning = function(text) {
          $('#book_delivery_location_warning p').empty().append(text);
          $('#book_delivery_location_warning').show();
        }
        var hideBookDeliveryLocationWarning = function() {
          $('#book_delivery_location_warning p').empty();
          $('#book_delivery_location_warning').hide();
        }
        var showBookDeliveryOrganisationNameDiv = function(text) {
          bookDeliveryOrganisationNameLabel.text(text);
          createRequirementAbbr(bookDeliveryOrganisationNameLabel, bookDeliveryOrganisationNameInput);
          bookDeliveryOrganisationNameDiv.show();
        }
        var hideBookDeliveryOrganisationNameDiv = function() {
          removeRequirementAbbr(bookDeliveryOrganisationNameLabel, bookDeliveryOrganisationNameInput);
          bookDeliveryOrganisationNameDiv.hide();
        }
        var showAttentionToDiv = function(text) {
          attentionToInput.val(text);
          attentionToDiv.show();
        }
        var hideAttentionToDiv = function() {
          attentionToInput.val('');
          attentionToDiv.hide();
        }

        if (selectedValue === '') {
          addressFormDiv.hide();
          hideBookDeliveryLocationWarning();
          return;
        }

        addressFormDiv.show();

        switch(selectedValue) {
          case 'home':
            showLetterboxDiv(letterboxLabelText);
            hideBookDeliveryOrganisationNameDiv();
            hideAttentionToDiv();
            hideBookDeliveryLocationWarning();
            break;

          case 'relative_home':
            showLetterboxDiv('Nom de la personne hébergeant la famille (nom sur la boîte aux lettres) ');
            hideBookDeliveryOrganisationNameDiv();
            showAttentionToDiv(`${parent1FirstName} ${parent1LastName}`);
            hideBookDeliveryLocationWarning();
            break;

          case 'pmi':
            hideLetterboxDiv();
            showBookDeliveryOrganisationNameDiv('Nom de la PMI ');
            $('#child_parent1_attributes_book_delivery_organisation_name').attr('placeholder', 'Ex : PMI Henri Barbusse');
            showAttentionToDiv(`${childFirstName} ${childLastName}`);
            hideBookDeliveryLocationWarning();
            break;

          case 'temporary_shelter':
            hideLetterboxDiv();
            showBookDeliveryOrganisationNameDiv("Nom complet de la structure d'accueil (hôtel, résidence sociale…) ")
            $('#child_parent1_attributes_book_delivery_organisation_name').attr('placeholder', '');
            showAttentionToDiv(`${parent1FirstName} ${parent1LastName}`);
            showBookDeliveryLocationWarning("<b>Nous vous recommandons de proposer à la famille de recevoir les livres à la PMI.</b> Les livres envoyés aux hébergements d'urgence (hôtels, CHU, etc.) sont souvent retournés à 1001mots.");
            break;

          case 'association':
            hideLetterboxDiv();
            showBookDeliveryOrganisationNameDiv("Nom complet de l'association ");
            $('#child_parent1_attributes_book_delivery_organisation_name').attr('placeholder', '');
            showAttentionToDiv(`${parent1FirstName} ${parent1LastName}`);
            showBookDeliveryLocationWarning("<b>Nous vous recommandons de proposer à la famille de recevoir les livres à la PMI.</b> Les livres envoyés aux associations (ex. maisons de quartier) sont souvent retournés à 1001mots.")
            break;

          case 'police_or_military_station':
            hideLetterboxDiv();
            showBookDeliveryOrganisationNameDiv('Nom complet de la caserne ou du commissariat ');
            $('#child_parent1_attributes_book_delivery_organisation_name').attr('placeholder', '');
            showAttentionToDiv(`${parent1FirstName} ${parent1LastName}`);
            showBookDeliveryLocationWarning("<b>Nous vous recommandons de proposer à la famille de recevoir les livres à la PMI.</b> Les livres envoyés aux casernes ou commissariats sont souvent retournés à 1001mots.");
            break;

          default:
            break;
        }
      });
    }

    childrenSourceSelect.select2();
    childrenSourceSelect.data().select2.$container.addClass("form-control");
    window.friendOption = []; // setup "Mon entourage" option
    // setup CAF options
    window.utmCaf = undefined;
    window.utmMsa = undefined;
    window.cafOptions = childrenSourceSelect.find('option').map(function() {
      return { id: $(this).val(), text: $(this).text() };
    }).get();
    $.ajax({
      type: 'GET',
      url: '/sources/friends'
    }).done(function(data) {
      window.friendOption = [{ id: data.id, text: data.name }];
    });

    var utmCaf = url.searchParams.get('utm_caf') || undefined;
    if (utmCaf !== undefined) {
      $.ajax({
        type: 'GET',
        url: '/sources/caf_by_utm?utm_caf='+utmCaf
      }).done(function(data) {
        window.utmCaf = data.id;
        childrenSourceSelect.val(window.utmCaf);
        childrenSourceSelect.trigger('change');
      });
    }

    var utmMsa = url.searchParams.get('utm_msa') || undefined;
    if (utmMsa !== undefined) {
      $.ajax({
        type: 'GET',
        url: '/sources/msa_by_utm?utm_msa='+utmMsa
      }).done(function(data) {
        window.utmMsa = data.id;
        childrenSourceSelect.val(window.utmMsa);
        childrenSourceSelect.trigger('change');
      });
    }

    if (pathName === '/inscription5' || pathName === '/inscriptionpartenaires') {
      var $source_department_select2 = $('#child_children_source_attributes_registration_department').select2();
      $source_department_select2.data().select2.$container.addClass("form-control");
    }

    $(document).on('input', "#child_parent2_attributes_first_name, #child_parent2_attributes_last_name, #child_parent2_attributes_phone_number", () => {
      var parent2Inputs = $("#child_parent2_attributes_first_name, #child_parent2_attributes_last_name, #child_parent2_attributes_phone_number");
      var parent2Fields= $("[class*='child_parent2_']");
      var atLeastOneHasValue = false;
      parent2Inputs.each(function() {
        if ($(this).val() !== '') {
          atLeastOneHasValue = true;
          return;
        }
      });

      parent2Inputs.attr("required", atLeastOneHasValue);

      if (atLeastOneHasValue === true) {
        parent2Fields.each(function() {
          if ($(this).children().first().find('abbr').length === 0) {
            var abbrElement = document.createElement('abbr');
            abbrElement.setAttribute('title', 'required');
            abbrElement.innerHTML = ' *'
            $(this).children().first().append(abbrElement);
          }
        });
      } else {
        parent2Fields.each(function() {
          var abbr = $(this).children().first().find('abbr');
          if (abbr.length !== 0) {
            abbr.remove();
          }
        });
      }
    });

    showCafSelection.apply($('#form_received_from'));

    $(document).on('change', 'select[id="form_received_from"]', showCafSelection);

    $(document).on('change', 'select[id="child_children_source_attributes_source_id"]', function() {
      $('select[id="child_children_source_attributes_registration_department"]').val('');
      $('select[id="child_children_source_attributes_registration_department"]').trigger('change');
      checkIfLocalPartnerHasDepartment();
    });

    $('.child-fields-container.hidden .btn.rm-child-btn').each(function() {
      initRmChildBtn(this);
    });
    $('.child-fields-container.hidden .btn.add-child-btn').each(function() {
      initAddChildBtn(this);
    });
  };

  $(document).ready(init);

})(jQuery);
