$(document).ready(function() {
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
		if (data.uris) {
            for (var i = 0; i < data.uris.length; i++) {
                $('#upload-image-panel').show();
                var uri = data.uris[i];
                var img;
                var thumb;
                if (uri.match(/\.(png|jpe?g)$/)) {
                    img = $('<img/>', {
                        class: "img-responsive img-thumbnail",
                        src: uri,
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
                            $('<code/>').text(uri)
                        )
                    )
                );

				$('#uploads').prepend(thumb);
                if (data.insert) {
                    $('#maintextarea').attr('readonly', 'readonly');
                    var body = $('#maintextarea').val();
                    if (uri.match(/\.pdf$/)) {
                        if (body.match(/^#ATTACH .*$/m)) {
                            body = body.replace(/^(#ATTACH .*)$/m, '$1 ' + uri);
                        }
                        else {
                            body = '#ATTACH ' + uri + "\n" + body;
                        }
                    }
                    else {
                        body = body + "\n\n[[" + uri + "]]\n\n";
                    }
                    $('#maintextarea').effect("highlight", {}, 2000);
                    $('#maintextarea').val(body);
                    $('#maintextarea').removeAttr('readonly');
                }
                else {
                    if ($('#maintextarea').val().search(uri) < 0) {
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
                    this.progressBar.text('0%');
				    $('#upload-progress').append(this.progressBar);
			    },
			    progress: function(progress) {
				    //received progress
                    console.log("Progress: " + progress);
				    this.progressBar.css("width", progress + "%");
                    this.progressBar.text(progress + "%");
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
});
