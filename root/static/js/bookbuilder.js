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
        $('.pdf-common-option').hide();
        $('.slides-option').hide();
        $('.pdf-option').hide();
        $('.epub-option').show();
    }
    else {
        $('.pdf-common-option').show();
        $('.epub-option').hide();
        if  (current_format == 'slides') {
            $('.pdf-option').hide();
            $('.slides-option').show();
        }
        else {
            $('.slides-option').hide();
            $('.pdf-option').show();
        }
    }
    if (current_format == 'slides') {
        $('.not-slides').hide();
    }
    else {
        $('.not-slides').show();
    }
}

function handle_papersize(prefix) {
    var hid = '#' + prefix + '-paper-height';
    var wid = '#' + prefix + '-paper-width';
    var height = $(hid).val();
    var width  = $(wid).val();
    if ((height === "0") || (width === "0")) {
        $(hid).val("0");
        $(wid).val("0");
    }
    show_hide_standard_papersizes(prefix);
}

function show_hide_standard_papersizes(prefix) {
    var hid = '#' + prefix + '-paper-height';
    var wid = '#' + prefix + '-paper-width';
    var standard = '#papersize';
    if (prefix == "crop") {
        standard = '#crop_papersize';
    }
    if (prefix == "areaset") {
        standard  = '#division';
    }
    var height = $(hid).val();
    var width  = $(wid).val();
    if (height && width && (height != "0") && (width != "0")) {
        $(standard).hide('fast');
    }
    else {
        $(standard).show('fast');
    }
}

function show_conditional_nocoverpage() {
    if ($('#nocoverpage').is(":checked")) {
        $('#coverpage_only_if_toc_container').hide('fast');
    }
    else {
        $('#coverpage_only_if_toc_container').show('fast');
    }
}

$(document).ready(function(){
    show_format_options();
    show_imposition();
    show_signature();
    show_image_options();
    show_opening();
    show_crop_options();
    handle_papersize('crop');
    handle_papersize('logical');
    handle_papersize('areaset');
    show_conditional_nocoverpage();
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
    $(".paper-select-handle").change(function() {
        var prefix = $(this).data('prefix');
        if ($(this).val() === "0") {
            handle_papersize(prefix);
        }
        else {
            show_hide_standard_papersizes(prefix);
        }
    });
    $("#bb-profiles-instructions").hide();
    $("form#bbform :input").change(function() {
        $("#bb-profiles-instructions").show();
        $("#bb-profiles-forms").hide();
    });
    $('#nocoverpage').click(function() {
        show_conditional_nocoverpage();
    });
});

