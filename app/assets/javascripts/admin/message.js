$(document).ready(function() {
    var call_goal_sms = $('#call_goals_sms')
    var call_goal = $("textarea[name='call_goal']")
    var additional_message = $("textarea[name='additional_message']")
    var call_goal_sms_field = $('#call_goal_div')
    var additional_message_field = $('#additional_message_div')
    var message = $("textarea[name='message']")
    var messageContent = "Bonjour !\nVoici votre petite mission :\n{CHAMP_PETITE_MISSION}\nQuand vous aurez essayé, cliquez sur ce lien pour me raconter comment ça s’est passé :\n{type_form_link}\n{CHAMP_MESSAGE_COMPLEMENTAIRE}\n1001mots"
    var childSupportId = new URLSearchParams(window.location.search).get('child_support_id')
    var parentSecurityCode = new URLSearchParams(window.location.search).get('parent_sc')
    var speakingLink = `${window.location.protocol}//${window.location.host}/c3/sf?cs=${childSupportId}&sc=${parentSecurityCode}`
    var observingLink = `${window.location.protocol}//${window.location.host}/c3/of?cs=${childSupportId}&sc=${parentSecurityCode}`

    function showNewFields() {
        call_goal_sms_field.show()
        additional_message_field.show()
    }
    function hideNewFields() {
        call_goal_sms_field.hide()
        additional_message_field.hide()
    }
    function normalMessage() {
        message.prop('readonly', false)
        message.val('')
    }
    function specificCall3Message(call3_goal) {
        if (call3_goal == 'call3_goals_speaking'){
            messageContentWithLink = messageContent.replace('{type_form_link}', speakingLink)
        }else if (call3_goal == 'call3_goals_observing') {
            messageContentWithLink = messageContent.replace('{type_form_link}', observingLink)
        }
        if (call_goal.val() !== ''){
            messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val())
        } else {
            messageContentRefreshed = messageContentWithLink
        }
    }

    hideNewFields()

    call_goal_sms.on('change', function() {
        var selectedValue = $(this).val()
        if (selectedValue == 'call3_goals_speaking' || selectedValue == 'call3_goals_observing') {
            message.css({'height': '250px'});
            message.val(messageContent)
            specificCall3Message(selectedValue)
            message.val(messageContentRefreshed)
            showNewFields()
            message.prop('readonly', true)
        } else {
            message.css({'height': 'auto'});
            normalMessage()
            hideNewFields()
        }
    })

    call_goal.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_MESSAGE_COMPLEMENTAIRE}', additional_message.val()).replace('{CHAMP_PETITE_MISSION}', $(this).val())
        message.val(messageContentRefreshed)
    })

    additional_message.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val()).replace('{CHAMP_MESSAGE_COMPLEMENTAIRE}', $(this).val())
        message.val(messageContentRefreshed)
    })
});
