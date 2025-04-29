(function($) {
  var url = new URL(window.location.href);
  var pathName = url.pathname;
  var childrenSourceSelect = $('#child_children_source_attributes_source_id');
  var sourceDetailsInput = $('#child_children_source_attributes_details');
  var sourceDetailsAlert = $('#children_source_detail_alert');
  var childBookDeliveryLocationSelect = $('#child_book_delivery_location');

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
    if (pathName === '/inscription5') {
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
    } else if (pathName === '/inscription5') {
      $('#registration_department_select').hide();
      checkIfLocalPartnerHasDepartment();
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

  var init = function() {
    if (childBookDeliveryLocationSelect.length > 0) {
      childBookDeliveryLocationSelect.select2();
      childBookDeliveryLocationSelect.data().select2.$container.addClass("form-control");
      var bookDeliveryOrganisationNameDiv = $('#book_delivery_organisation_name_div');
      var bookDeliveryOrganisationNamelabel = $('label[for="child_parent1_attributes_book_delivery_organisation_name"]');
      var bookDeliveryOrganisationNameInput = $('#child_parent1_attributes_book_delivery_organisation_name');
      var attentionToDiv = $('#attention_to_div');
      var attentionToInput = $('#child_parent1_attributes_attention_to');
      var letterboxLabel = $('label[for="child_parent1_attributes_letterbox_name"]');
      var letterboxLableText = 'Nom de famille sur la boîte aux lettres ';

      bookDeliveryOrganisationNameDiv.hide();
      attentionToDiv.hide();

      childBookDeliveryLocationSelect.on('change', function () {
        var selectedValue = $(this).val();
        var parent1FirstName = $('#child_parent1_attributes_first_name').val();
        var parent1LastName = $('#child_parent1_attributes_last_name').val();
        var childFirstName = $('#child_first_name').val();
        var childLastName = $('#child_last_name').val();


        switch(selectedValue) {
          case 'home':
            letterboxLabel.text(letterboxLableText);
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNamelabel.removeClass('required').addClass('optional');
            bookDeliveryOrganisationNameInput.removeAttr('required');
            bookDeliveryOrganisationNameInput.val('');
            bookDeliveryOrganisationNameDiv.hide();
            attentionToInput.val('');
            attentionToDiv.hide();
            var abbr = bookDeliveryOrganisationNamelabel.find('abbr');
            if (abbr.length !== 0) {
              abbr.remove();
            }
            break;

          case 'relative_home':
            letterboxLabel.text('Nom de la personne hébergeant la famille (nom sur la boîte aux lettres)');
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNameInput.val('');
            bookDeliveryOrganisationNameDiv.hide();
            attentionToInput.val(`${parent1FirstName} ${parent1LastName}`);
            attentionToDiv.show()
            break;

          case 'pmi':
            letterboxLabel.text(letterboxLableText);
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNamelabel.removeClass('optional').addClass('required');
            bookDeliveryOrganisationNameInput.attr('required', true);
            bookDeliveryOrganisationNamelabel.text('Nom de la PMI ');
            bookDeliveryOrganisationNameInput.val('');
            if (bookDeliveryOrganisationNamelabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              bookDeliveryOrganisationNamelabel.append(abbrElement);
            }
            attentionToInput.val(`${childFirstName} ${childLastName}`);
            attentionToDiv.show();
            bookDeliveryOrganisationNameDiv.show();
            break;

          case 'temporary_shelter':
            letterboxLabel.text(letterboxLableText);
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNamelabel.removeClass('optional').addClass('required');
            bookDeliveryOrganisationNameInput.attr('required', true);
            bookDeliveryOrganisationNamelabel.text('Nom complet de la structure d’accueil (hôtel, résidence sociale…) ');
            bookDeliveryOrganisationNameInput.val('');
            if (bookDeliveryOrganisationNamelabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              bookDeliveryOrganisationNamelabel.append(abbrElement);
            }
            attentionToInput.val(`${parent1FirstName} ${parent1LastName}`);
            attentionToDiv.show();
            bookDeliveryOrganisationNameDiv.show();
            break;

          case 'association':
            letterboxLabel.text(letterboxLableText);
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNamelabel.removeClass('optional').addClass('required');
            bookDeliveryOrganisationNameInput.attr('required', true);
            bookDeliveryOrganisationNamelabel.text('Nom complet de l’association ');
            bookDeliveryOrganisationNameInput.val('');
            if (bookDeliveryOrganisationNamelabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              bookDeliveryOrganisationNamelabel.append(abbrElement);
            }
            attentionToInput.val(`${parent1FirstName} ${parent1LastName}`);
            attentionToDiv.show();
            bookDeliveryOrganisationNameDiv.show();
            break;

          case 'police_or_military_station':
            letterboxLabel.text(letterboxLableText);
            if (letterboxLabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              letterboxLabel.append(abbrElement);
            }
            bookDeliveryOrganisationNamelabel.removeClass('optional').addClass('required');
            bookDeliveryOrganisationNameInput.attr('required', true);
            bookDeliveryOrganisationNamelabel.text('Nom complet de la caserne ou du commissariat ');
            bookDeliveryOrganisationNameInput.val('');
            if (bookDeliveryOrganisationNamelabel.find('abbr').length === 0) {
              var abbrElement = document.createElement('abbr');
              abbrElement.setAttribute('title', 'required');
              abbrElement.innerHTML = ' *'
              bookDeliveryOrganisationNamelabel.append(abbrElement);
            }
            attentionToInput.val(`${parent1FirstName} ${parent1LastName}`);
            attentionToDiv.show();
            bookDeliveryOrganisationNameDiv.show();
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

    if (pathName === '/inscription5') {
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
