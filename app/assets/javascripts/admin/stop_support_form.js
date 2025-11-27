$(document).ready(function() {
    const checkbox_labels = {
        program: "J’ai explicitement informé la famille que ne plus vouloir des livres, des appels ou des SMS revenait à mettre fin à l’accompagnement et elle m’a confirmé vouloir arrêter OU la famille m’a explicitement demandé à ne plus recevoir l’accompagnement 1001mots.",
        professional: "J’ai eu des éléments factuels qui prouvent que la famille est en fait un.e professionnel.le de santé qui souhaite tester l’accompagnement dans le cadre de son travail.",
        problematic_case: "J’ai validé l’arrêt de cette famille avec une coordinatrice.",
        very_advanced_practices: "J'ai constaté que la famille maîtrise déjà les pratiques recommandées et n'a pas besoin de notre accompagnement.",
        registered_by_partner_without_consent: "J'ai confirmé avec la famille qu'elle n'a jamais donné son accord pour participer au programme et ne souhaite pas continuer.",
        family_limited_french_for_support: "J'ai tenté d'adapter ma communication mais la barrière linguistique empêche réellement la famille de bénéficier du programme.",
        family_unresponsive_after_adaptation: "J'ai essayé d'adapter les échanges (SMS, traduction, etc.) et je constate que la famille ne répond plus ou que le programme n'a pas l'impact souhaité."
    }
    let radios = $(".stop-support-form-radio");
    let checkbox = $("#stop-support-form-checkbox");
    let validation = $("#stop-support-form-submit");
    let checkbox_label = $('#checkbox-label');
    let form_details = $('#form-details');
    form_details.hide();
    validation.prop('disabled', true);
    radios.change(function() {
        checkbox.prop('checked', false);
        validation.prop('disabled', true);
        if ($(this).prop('checked')) {
            form_details.show();
            checkbox_label.text(checkbox_labels[$(this).val()]);
        } else {
            form_details.hide();
        }
    })
    checkbox.change(function() {
        validation.prop('disabled', !$(this).prop('checked'));
    });
});
