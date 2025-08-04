(function($) {
  const DATA_KEY = 'data-maps-autocomplete';

  let onPlaceChanged = function(input, target, place) {

    $(input).val(place.formatted_address);

    if(target.formatted) {
      $(target.formatted).val(place.formatted_address);
    }

    if(target.locality) {
      $(target.locality).val(null);
    }
    if(target.postal_code) {
      $(target.postal_code).val(null);
    }

    let address = "";
    for (const component of place.address_components) {
      const types = component.types;
      if (types.includes('street_number')) {
        address = component.short_name;
      }
      if (types.includes('route')) {
        address += " " + component.short_name;
      }
      if (types.includes('locality')) {
        if(target.locality) {
          $(target.locality).val(component.long_name);
        }
      }
      if (types.includes('postal_code')) {
        if(target.postal_code) {
          $(target.postal_code).val(component.short_name);
        }
      }
    }
    if (target.address) {
      $(input).val(address);
    }
  };

  let onPlaceRemoved = function(input, target) {

    if(target.formatted) {
      $(target.formatted).val(null);
    }
    if(target.locality) {
      $(target.locality).val(null);
    }
    if(target.postal_code) {
      $(target.postal_code).val(null);
    }
  }

  let initInput = function(input) {
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
    $('['+DATA_KEY+']').each(function() {
      initInput(this);
    });
  };

  $(document).ready(init);
})(jQuery);
