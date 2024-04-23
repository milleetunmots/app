$(document).ready(function() {
    const checkbox_labels = {
        program: "J’ai explicitement informé la famille que ne plus vouloir des livres, des appels ou des SMS revenait à mettre fin à l’accompagnement et elle m’a confirmé vouloir arrêter OU La famille m’a explicitement demandé à ne plus recevoir l’accompagnement 1001mots.",
        popi: "J’ai eu des éléments factuels qui prouvent que la famille a un niveau socio-économique élevé (bac+5, revenu très élevé...)",
        professional: "J’ai eu des éléments factuels qui prouvent que la famille est en fait un.e professionnel.le de santé qui souhaite tester l’accompagnement dans le cadre de son travail",
        problematic_case: "J’ai validé l’arrêt de cette famille avec une coordinatrice"
    }
    let radios = document.querySelectorAll("input[type='radio']");
    let checkbox = document.querySelector("input[type='checkbox']");
    let checkbox_label = document.getElementById('checkbox-label');
    let form_details = document.getElementById('form-details');
    let validation = document.querySelector("input[type='submit']");
    form_details.style.display = 'none';
    validation.disabled = true;
    radios.forEach(function(radio) {
        radio.addEventListener('change', function() {
            if(radio.checked) {
                form_details.style.display = 'block';
                checkbox_label.textContent = checkbox_labels[radio.value]
            } else {
                form_details.style.display = 'none';
            }
        })
    });
    checkbox.addEventListener('change', function() {
        if (checkbox.checked) {
            validation.disabled = false;
        } else {
            validation.disabled = true;
        }
    });
});