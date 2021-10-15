(function($) {
  const DATA_KEY = 'data-maps-autocomplete';

  let onPlaceChanged = function(input, target, place) {
    // console.log('[Maps Autocomplete] onPlaceChanged', input, target, place);

    $(input).val(place.formatted_address);

    if(target.formatted) {
      $(target.formatted).val(place.formatted_address);
    }

    // clean old values for components
    if(target.locality) {
      $(target.locality).val(null);
    }
    if(target.postal_code) {
      $(target.postal_code).val(null);
    }

    // set new values
    console.log (place.address_components)
    let address = "";
    for (const component of place.address_components) {
      const componentType = component.types[0];
      switch (componentType) {
        case "street_number":
          address = component.short_name;
          break;
        case "route":
          address += " " + component.short_name;
          break;
        case "locality":
          if(target.locality) {
            $(target.locality).val(component.long_name);
          }
          break;
        case "postal_code":
          if(target.postal_code) {
            $(target.postal_code).val(component.short_name);
          }
          break;
        default:
        // do nothing
      }
    }
    if (target.address) {
      $(input).val(address);
    }
  };

  let onPlaceRemoved = function(input, target) {
    // console.log('[Maps Autocomplete] onPlaceRemoved', input, target);

    $(target.latitude).val('');
    $(target.longitude).val('');
    if(target.formatted) {
      $(target.formatted).val(null);
    }
    if(target.name) {
      $(target.name).val(null);
    }
    if(target.locality) {
      $(target.locality).val(null);
    }
    if(target.countrycode) {
      $(target.countrycode).val(null);
    }
  }

  let initInput = function(input) {
    // console.log('[Maps Autocomplete] initInput', input);
    let $input = $(input);
    let options = JSON.parse($input.attr(DATA_KEY));
    $input.removeAttr(DATA_KEY);

    let target = options['target'];
    delete options['target'];

    let autocomplete = new google.maps.places.Autocomplete(
      input,
      $.extend({
        types: ['geocode']
      }, options)
    );
    google.maps.event.addListener(
      autocomplete,
      'place_changed',
      function(){
        // console.log('place changed', this);
        onPlaceChanged(input, target, this.getPlace());
      }
    );
    $input.on('change', function() {
      if($input.val() == '') {
        onPlaceRemoved(input, target);
      }
    });
  };

  let init = function() {
    // console.log('[Maps Autocomplete] init');
    $('['+DATA_KEY+']').each(function() {
      initInput(this);
    });
  };

  $(document).ready(init);
})(jQuery);
