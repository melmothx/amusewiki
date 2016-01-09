function show_opening() {
    if ($('#twoside').is(":checked")) {
        $('#choose-opening').show('fast');
    }
    else {
        $('#choose-opening').hide('fast');
    }
}
function show_signature() {
    if ($('#schema2up').is(":checked")) {
        $('#signature-explanation').show();
    }
    else {
        $('#signature-explanation').hide();
    }
    if ($('#schema4up').is(":checked")) {
        $('#signature-explanation-4up').show();
    }
    else {
        $('#signature-explanation-4up').hide();
    }
}
function show_imposition() {
    if ($('#imposed').is(":checked")) {
        $('#imposition-options').show('fast');
    }
    else {
        $('#imposition-options').hide('fast');
    }
}
function show_image_options() {
    if ($('#coverfile-is-present').length || $('#coverimage').val()) {
        $('.image-options').show('fast');
    }
    else {
        $('.image-options').hide('fast');
    }
}
function show_crop_options() {
    if ($("#crop_marks").is(":checked")) {
        $('#cropmarks-paper-options').show('fast');
    }
    else {
        $('#cropmarks-paper-options').hide('fast');
    }
}
function show_format_options() {
    var current_format = $("form#bbform input[name=format]:checked").val();
    if (current_format == 'epub') {
        $('.pdf-common-option').hide('fast');
        $('.epub-option').show('fast');
        $('.slides-option').hide('fast');
        $('.pdf-option').hide('fast');
    }
    else {
        $('.pdf-common-option').show('fast');
        $('.epub-option').hide('fast');
        if  (current_format == 'slides') {
            $('.pdf-option').hide();
            $('.slides-option').show();
        }
        else {
            $('.pdf-option').show();
            $('.slides-option').hide();

        }
    }
    if (current_format == 'slides') {
        $('.not-slides').hide();
    }
    else {
        $('.not-slides').show();
    }
}
$(document).ready(function(){
    show_format_options();
    show_imposition();
    show_signature();
    show_image_options();
    show_opening();
    show_crop_options();
    $('#imposed').click(function() {
        show_imposition();
    });
    $('#twoside').click(function() {
        show_opening();
    });
    $('#crop_marks').click(function() {
        show_crop_options();
    });


    $('.choose-schema').click(function() {
        show_signature();
    });
    $(".format-radio").change(function() {
        show_format_options();
    });
    $("#coverimage").change(function() {
        if ($(this).val()) {
            $('.image-options').show('fast');
        }
    });
});

