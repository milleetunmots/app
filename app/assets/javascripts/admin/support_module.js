$(document).ready(function() {
  let $supportModuleTheme = $("#support_module_theme");
  let $ages = $("#support_module_age_ranges");
  const module_zero_age_ranges = [
    { value: 'four_to_ten', text: '4 - 10 mois' },
    { value: 'eleven_to_sixteen', text: '11 - 16 mois' },
    { value: 'seventeen_to_twenty_two', text: '17 - 22 mois' },
    { value: 'twenty_three_and_more', text: '23 mois et plus' }
  ];
  const age_ranges = [
    { value: 'four_to_eleven', text: '4 - 11 mois' },
    { value: 'twelve_to_seventeen', text: '12 - 17 mois' },
    { value: 'eighteen_to_twenty_three', text: '18 - 23 mois' },
    { value: 'twenty_four_to_twenty_nine', text: '24 - 29 mois' },
    { value: 'thirty_to_thirty_five', text: '30 - 35 mois' },
    { value: 'thirty_six_to_forty', text: '36 - 40 mois' },
    { value: 'forty_one_to_forty_four', text: '41 - 44 mois' }
  ];

  let filling = function(range) {
    range.forEach(function(age) {
      $ages.append($('<option>', {
        value: age.value,
        text: age.text
      }));
    });
  }

  $supportModuleTheme.on("change", function() {
    $ages.empty();
    if ($supportModuleTheme.val() === 'language_module_zero') {
      filling(module_zero_age_ranges);
    } else {
      filling(age_ranges);
    }
  });
});
