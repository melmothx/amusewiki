$(document).ready(function(){
    $("button#amw-edit-form-ajax-button").click(function(e) {
        var musedata = $("#museform").serializeArray();
        var museedit = $("#museform").attr('action');
        musedata.push({ name: 'preview', value: 1 });
        musedata.push({ name: 'ajax', value: 1 });
        console.log(musedata);
        $.ajax({
            type: 'POST',
            url: museedit,
            data: musedata,
            dataType : 'json',
            success: function(data) {
                console.log(data);
                $('#amw-text-edit-preview-box').load(data.preview_uri +
                                                     '?bare=1 #amw-text-preview-page');
                $('div.amw-fixed-panel-edit').effect("highlight", {}, 10000);
                if (data.error_msg) {
                    $('div#amw-edit-ajax-warnings-container').show();
                    $('div#amw-edit-ajax-warnings').text(data.error_msg);
                }
                else {
                    $('div#amw-edit-ajax-warnings-container').hide();
                }
            }
        });
    });
});

