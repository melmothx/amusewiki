$(document).ready(function() {
    $('#upload-image-panel').hide();
    $('#upload-button-no-js-container').remove();
    $('.image-listing-no-js').remove();
    var maintextarea = $('#maintextarea');
    var messages = {};
    $.get("/api/lexicon.json", function(data) {
        messages = data;
    });
    function is_image(uri) {
        return uri.match(/\.(png|jpe?g)$/);
    }
    function l(string) {
        return messages[string] || string;
    }
    function parse_uris_data (data) {
        console.log(data);
        var body = maintextarea.val();
		if (data.uris) {
            for (var i = 0; i < data.uris.length; i++) {
                $('#upload-image-panel').show();
                var uri = data.uris[i];
                var img;
                var thumb;
                var fa_icon;
                if (is_image(uri)) {
                    img = $('<img/>', {
                        class: "img-responsive img-thumbnail",
                        src: uri,
                        alt: uri
                    });
                }
                else {
                    fa_icon = 'fa-file';
                    if (uri.match(/\.(pdf)/)) {
                        fa_icon = 'fa-file-pdf-o';
                    }
                    else if (uri.match(/\.(avi|mkv|mov|mp4|mpe?g|ogv|webm)$/)) {
                        fa_icon = 'fa-file-video-o';
                    }
                    else if (uri.match(/\.(mp3|flac|ogg)/)) {
                        fa_icon = 'fa-file-audio-o';
                    }
                    img = $("<a/>", { 'href': uri }).append(
                        $('<span/>', { class: "fa " + fa_icon + " fa-2x fa-border" })
                    );
                }

                var thumb = $("<div/>", { 'class': 'upload-item  col-sm-6 col-md-4' }).append(
                    $('<div/>', { class: "thumbnail" }).append(
                        img,
                        $('<div/>', { class: "caption" }).append(
                            $('<code/>').text(uri),
                            $('<br>')
                        )
                    )
                );
                var caption = thumb.find('.caption');
                var uri_is_present = 0;
                var uri_is_cover = 0;
                if (data.insert) {
                    insert_uri(uri);
                    uri_is_present = 1;
                }
                else if (body.search(uri) < 0) {
                    // not present, mark it and add a removal button
                    caption.prepend($('<div/>',
                                      { 'class': "text-warning unused-attachment",
                                        'href': "#"
                                      }).append(
                                          $('<span/>', {
                                              'class': "fa fa-warning fa-border",
                                              'title': l('Unused attachment')
                                          }),
                                          $('<span/>').text(l('Unused attachment'))
                                      ));
                }
                else {
                    uri_is_present = 1;
                }
                var caption_string;
                if (uri_is_present) {
                    caption_string = l("File already in the body");
                }
                else if (is_image(uri)) {
                    caption_string = l("Insert the file into the body at the cursor position");
                }
                else {
                    caption_string = l("Attach");
                }
                caption.append($('<a/>',
                                 {
                                     'data-uri': uri,
                                     'href': "#",
                                     'class': "amw-image-use use-image-as-picture" + ( uri_is_present ? '-disabled' : ''),
                                     'title': caption_string
                                 }).append(
                                     $("<span/>", { class: "fa fa-picture-o fa-2x fa-border" })
                                 ));

                if (is_image(uri)) {
                    if (body.search('#cover ' + uri) < 0) {
                        uri_is_cover = 0;
                    }
                    else {
                        uri_is_cover = 1;
                    }
                    caption.append($('<a/>', { "data-uri": uri,
                                               "href": "#",
                                               "class": "amw-image-use use-image-as-cover" + (uri_is_cover ? '-disabled' : ''),
                                               "title": (uri_is_cover ?
                                                         l("Image already set as cover") :
                                                         l("Use the image as cover"))
                                             }
                                    ).append($("<span/>", { class: "fa fa-file-image-o fa-2x fa-border" })));
                }
                caption.append($('<a/>',
                                 {
                                     'data-uri': uri,
                                     'data-target': $('#uploads').data('removal-url'),
                                     'href': "#",
                                     'class': "amw-image-use remove-attachment-action" + ( uri_is_present ? '-disabled' : ''),
                                     'title': (uri_is_present ? l("Please remove this file from the body first") : l("Remove"))
                                 }).append(
                                     $("<span/>", { class: "fa fa-trash fa-2x fa-border" })
                                 ));
                caption.children('.amw-image-use').tooltip();
		        $('#uploads').prepend(thumb);
            }
		}
        else {
			//our application returned an error
            $('#uploads-errors').text(data.error.message).show();
		}
    }
    function refresh_attachments() {
        if ($('#uploads').data('listing-url')) {
            $('#uploads-static-listing').remove();
            $.get($('#uploads').data('listing-url'), function(data) {
                $('#uploads').children().remove();
                parse_uris_data(data, $('#uploads'));
            });
        }
    }
    function insert_uri(uri) {
        maintextarea.attr('readonly', 'readonly');
        var body = maintextarea.val();
        var finaloffset;
        if (is_image(uri)) {
            var chunk = "\n\n[[" + uri + " f]]\n\n";
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
        else {
            if (body.match(/^#ATTACH .*$/m)) {
                body = body.replace(/^(#ATTACH .*)$/m, '$1 ' + uri);
            }
            else {
                body = '#ATTACH ' + uri + "\n" + body;
            }
        }
        maintextarea.val(body);
        maintextarea.removeAttr('readonly');
        if (finaloffset) {
            maintextarea.prop('selectionStart', finaloffset);
            maintextarea.prop('selectionEnd', finaloffset);
        }
        maintextarea.effect("highlight", {}, 1000);
        maintextarea.focus();
        $.event.trigger({ type : 'keypress' });
    }

    refresh_attachments();

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
                maxFileSize: amw_batch_upload_settings.max_file_size,
                data: {
                    insert: $("#add-attachment-to-body").is(":checked") ? 1 : 0,
                    split_pdf: $("#split-pdf").is(":checked") ? 1 : 0,
                },
                expect: "json",
                allowedExts: amw_batch_upload_settings.extensions,
                allowedTypes: amw_batch_upload_settings.mime_types
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
        maintextarea.attr('readonly', 'readonly');
        $.post(target, data, function(res) {
            // console.log(res);
            $('#editing-warnings-inline').hide();
            $('#editing-warnings-inline-footnotes').hide();
            if (res.success && res.body) {
                maintextarea.effect("highlight", {}, 1000);
                // console.log("Updating with " + res.body);
                maintextarea.val(res.body);
                load_preview();
            }
            if (res.error) {
                $('#editing-warnings-inline').text(res.error.message).show();
                if (res.error.footnotesdebug) {
                    $('#editing-warnings-inline-footnotes').text(res.error.footnotesdebug).show();
                }
            }
            maintextarea.removeAttr('readonly');
        });
        refresh_attachments();
    });

    $(document).on('click', '.remove-attachment-action-disabled', function (e) {
        e.preventDefault();
    });
    $(document).on('click', '.remove-attachment-action', function (e) {
        e.preventDefault();
        var block = $(this).closest('.upload-item');
        var target = $(this).data('target');
        var uri = $(this).data('uri');
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

    $(document).on('click', '.use-image-as-picture-disabled', function (e) {
        e.preventDefault();
    });
    $(document).on('click', '.use-image-as-picture', function (e) {
        e.preventDefault();
        var uri = $(this).data('uri');
        if (uri) {
            insert_uri(uri);
            refresh_attachments();
        }
    });

    $(document).on('click', '.use-image-as-cover-disabled', function (e) {
        e.preventDefault();
    });
    $(document).on('click', '.use-image-as-cover', function(e) {
        e.preventDefault();
        var uri = $(this).data('uri');
        if (uri) {
            maintextarea.attr('readonly', 'readonly');
            var body = maintextarea.val();
            if (body.match(/^#cover .*$/m)) {
                body = body.replace(/^#cover .*$/m, '#cover ' + uri);
            }
            else {
                body = '#cover ' + uri + "\n" + body;
            }
            maintextarea.val(body);
            maintextarea.removeAttr('readonly');
            maintextarea.effect("highlight", {}, 1000);
            refresh_attachments();
        }
    });
});
