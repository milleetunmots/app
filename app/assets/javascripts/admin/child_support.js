$(document).ready(function() {
  let parent1 = $('#child_parent1_id');
  let parent2 = $('#child_parent2_id');

  parent1.change(function() {
    $.getJSON(`/parent/${$('#child_parent1_id').val()}/first_child`, function(child) {
      $('#child_registration_source').val(child.registration_source).change();
      $('#child_registration_source_details').val(child.registration_source_details);
    });
  });

  parent2.change(function() {
    $.getJSON(`/parent/${$('#child_parent2_id').val()}/first_child`, function(child) {
      $('#child_registration_source').val(child.registration_source).change();
      $('#child_registration_source_details').val(child.registration_source_details);
    });
  });
});
