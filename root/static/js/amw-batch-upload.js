$(document).ready(function() {
    $('#upload-image-panel').hide();
    $('#upload-button-no-js-container').remove();
    var list = $('#uploads').data('listing-url');
    var messages = {};
    $.get("/api/lexicon.json", function(data) {
        messages = data;
    });
    function l(string) {
        return messages[string] || string;
    }
    function parse_uris_data (data) {
        console.log(data);
        var maintextarea = $('#maintextarea');
		if (data.uris) {
            for (var i = 0; i < data.uris.length; i++) {
                $('#upload-image-panel').show();
                var uri = data.uris[i];
                var img;
                var thumb;
                if (uri.match(/\.(png|jpe?g)$/)) {
                    img = $('<img/>', {
                        class: "img-responsive img-thumbnail",
                        src: uri + '?i=' + Date.now(),
                        alt: uri
                    });
                }
                else {
                    img = $('<span/>', { class: "fa fa-file-pdf-o fa-2x fa-border" });
                }
                var thumb = $("<div/>", { 'class': 'upload-item  col-sm-6 col-md-4' }).append(
                    $('<div/>', { class: "thumbnail" }).append(
                        img,
                        $('<div/>', { class: "caption" }).append(
                            $('<code/>').text(uri),
                            ' ',
                            $('<a/>', { 'data-uri': uri,
                                           'data-target': $('#uploads').data('removal-url'),
                                           class: "badge remove-attachment-action",
                                        title:l("Remove")}).text("X")
                        )
                    )
                );

				$('#uploads').prepend(thumb);
                if (data.insert) {
                    maintextarea.attr('readonly', 'readonly');
                    var body = maintextarea.val();
                    var finaloffset;
                    if (uri.match(/\.pdf$/)) {
                        if (body.match(/^#ATTACH .*$/m)) {
                            body = body.replace(/^(#ATTACH .*)$/m, '$1 ' + uri);
                        }
                        else {
                            body = '#ATTACH ' + uri + "\n" + body;
                        }
                    }
                    else {
                        var chunk = "\n\n[[" + uri + "]]\n\n";
                        var offset = maintextarea.prop('selectionStart');
                        if (offset) {
                            var before = body.substring(0, offset);
                            var after = body.substring(offset);
                            console.log("Offset is " + offset);
                            body = before + chunk + after;
                            finaloffset = offset + chunk.length;
                        }
                        else {
                            body = body + chunk;
                        }
                    }
                    maintextarea.val(body);
                    maintextarea.removeAttr('readonly');
                    if (finaloffset) {
                        maintextarea.prop('selectionStart', finaloffset);
                        maintextarea.prop('selectionEnd', finaloffset);
                    }
                    maintextarea.focus();
                    $.event.trigger({ type : 'keypress' });
                }
                else {
                    if (maintextarea.val().search(uri) < 0) {
                        // not present, mark it
                        thumb.append(
                            $('<div/>', { class: "alert alert-warning" })
                                .append($('<span/>', { class: "fa fa-warning" }),
                                        ' ',
                                        $('<span/>').text(l('Unused attachment')))
                        );
                    }
                }
            }
		}
        else {
			//our application returned an error
            $('#uploads-errors').text(data.error.message).show();
		}
    }
    if (list) {
        $('#uploads-static-listing').remove();
        $.get(list, function(data) {
            parse_uris_data(data, $('#uploads'));
        });
    }
    $('#attachment').change(function() {
        var target = $(this).data('upload-url');
        if (target) {
            $(this).simpleUpload(target, {
                start: function(file) {
				    //upload started
                    $('#uploads-errors').hide();
				    this.progressBar = $('<div/>', { class: "progress-bar",
                                                     role: "progressbar",
                                                     style: "width: 1%" });
                    this.progressBar.text(file.name);
				    $('#upload-progress').append(this.progressBar);
			    },
			    progress: function(progress) {
				    //received progress
				    this.progressBar.css("width", progress + "%");
			    },
			    success: function(data) {
				    //upload successful
				    this.progressBar.remove();
                    parse_uris_data(data);
			    },
			    error: function(error) {
				    //upload failed
                    console.log(error);
				    this.progressBar.remove();
                    $('#uploads-errors').text(l(error.name)).show();
			    },
                maxFileSize: 8 * 1028 * 1028,
                data: {
                    insert: $("#add-attachment-to-body").is(":checked") ? 1 : 0,
                    split_pdf: $("#split-pdf").is(":checked") ? 1 : 0,
                },
                expect: "json",
                allowedExts: ["pdf", "jpg", "jpeg", "png" ],
                allowedTypes: ["application/pdf", "image/png", "image/jpeg"]
		    });
        }
    });
    $("button#amw-edit-form-preview-button").click(function(e) {
        e.preventDefault();
        var target = $(this).data('ajax-post');
        // collect the params
        // https://stackoverflow.com/questions/2276463/how-can-i-get-form-data-with-javascript-jquery
        var data = $('form#museform')
            .serializeArray()
            .reduce(function(obj, item) {
                obj[item.name] = item.value;
                return obj;
            }, {});
        data['preview'] = 1;
        // console.log(data);
        $('#maintextarea').attr('readonly', 'readonly');
        $.post(target, data, function(res) {
            // console.log(res);
            if (res.success && res.body) {
                $('#maintextarea').effect("highlight", {}, 1000);
                console.log("Updating with " + res.body);
                $('#maintextarea').val(res.body);
                $('#editing-warnings-inline').hide();
                load_preview();
            }
            if (res.error) {
                $('#editing-warnings-inline').text(res.error.message).show();
            }
            $('#maintextarea').removeAttr('readonly');
        });
    });
    $(document).on('click', '.remove-attachment-action', function (e) {
        var block = $(this).closest('.upload-item');
        var target = $(this).data('target');
        var uri = $(this).data('uri')
        if (block && target && uri) {
            console.log("Clicked on removal: " + target + " " + uri);
            $.post(target,
                   { "remove": uri},
                   function (res) {
                       console.log("Posting to " + target  + " done");
                       console.log(res);
                       if (res.success) {
                           block.remove();
                       }
                   });
        }
    });
});
