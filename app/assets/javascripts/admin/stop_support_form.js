$(document).ready(function() {
    const checkbox_labels = {
        program: "J’ai explicitement informé la famille que ne plus vouloir des livres, des appels ou des SMS revenait à mettre fin à l’accompagnement et elle m’a confirmé vouloir arrêter OU la famille m’a explicitement demandé à ne plus recevoir l’accompagnement 1001mots.",
        popi: "J’ai eu des éléments factuels qui prouvent que la famille a un niveau socio-économique élevé (bac+5, revenu très élevé...).",
        professional: "J’ai eu des éléments factuels qui prouvent que la famille est en fait un.e professionnel.le de santé qui souhaite tester l’accompagnement dans le cadre de son travail.",
        problematic_case: "J’ai validé l’arrêt de cette famille avec une coordinatrice.",
        renunciation: "J’envoie un SMS à la famille qui explique que ne plus vouloir des livres, des appels ou des SMS revenait à mettre fin à l’accompagnement, la famille pourra cliquer sur un lien qui arrêtera son accompagnement immédiatement et définitivement."
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
